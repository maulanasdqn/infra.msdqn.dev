/*
 * Shopee (com.shopee.id) anti-frida / anti-root bypass.
 *
 * Use with the Python loader (shopee-hook.py) or frida CLI:
 *   frida -H 127.0.0.1:29170 -f com.shopee.id -l shopee-bypass.js
 *
 * Requires:
 *   - Stealth kernel (proc maps filter hides frida-agent from /proc/self/maps)
 *   - frida-start (renamed binary on non-standard port)
 *   - KSU stealth module (boot state / build type props)
 */

var libc = Process.findModuleByName("libc.so");

var dominated = ["gmain", "gdbus", "gum-js", "pool-frida", "frida", "linjector"];

var openFn = new NativeFunction(libc.findExportByName("open"), "int", ["pointer", "int"]);
var writeFn = new NativeFunction(libc.findExportByName("write"), "int", ["int", "pointer", "int"]);
var closeFn = new NativeFunction(libc.findExportByName("close"), "int", ["int"]);

Process.enumerateThreads().forEach(function(t) {
    if (!t.name) return;
    for (var i = 0; i < dominated.length; i++) {
        if (t.name.toLowerCase().indexOf(dominated[i]) !== -1) {
            var path = Memory.allocUtf8String("/proc/self/task/" + t.id + "/comm");
            var fake = "binder:" + (t.id % 1000);
            var fakeBuf = Memory.allocUtf8String(fake);
            var fd = openFn(path, 1);
            if (fd >= 0) { writeFn(fd, fakeBuf, fake.length); closeFn(fd); }
            console.log("[+] renamed tid " + t.id + " '" + t.name + "' -> " + fake);
            break;
        }
    }
});

Interceptor.attach(libc.findExportByName("prctl"), {
    onEnter: function(args) {
        if (args[0].toInt32() === 15) {
            try {
                var name = args[1].readUtf8String();
                if (name) {
                    var nl = name.toLowerCase();
                    for (var i = 0; i < dominated.length; i++) {
                        if (nl.indexOf(dominated[i]) !== -1) {
                            args[1].writeUtf8String("hwuiTask" + (Process.getCurrentThreadId() % 100));
                            break;
                        }
                    }
                }
            } catch(e) {}
        }
    }
});

Interceptor.attach(libc.findExportByName("connect"), {
    onEnter: function(args) {
        try {
            if (args[1].readU16() === 2) {
                var port = (args[1].add(2).readU8() << 8) | args[1].add(3).readU8();
                if (port === 27042 || port === 27043) {
                    console.log("[!] blocked port " + port + " scan");
                    args[1].add(2).writeU8(0);
                    args[1].add(3).writeU8(1);
                }
            }
        } catch(e) {}
    }
});

Interceptor.attach(libc.findExportByName("_exit"), {
    onEnter: function(args) {
        console.log("[!] _exit(" + args[0] + ") blocked");
        args[0] = ptr(0);
    }
});

Interceptor.attach(libc.findExportByName("kill"), {
    onEnter: function(args) {
        if (args[0].toInt32() === Process.id) {
            var sig = args[1].toInt32();
            if (sig === 9 || sig === 6) {
                console.log("[!] kill(self, " + sig + ") blocked");
                args[1] = ptr(0);
            }
        }
    }
});

setTimeout(function() {
Java.perform(function() {
    try {
        var File = Java.use("java.io.File");
        File.exists.implementation = function() {
            var p = this.getAbsolutePath();
            if (p.indexOf("/su") !== -1 || p.indexOf("frida") !== -1 ||
                p.indexOf("magisk") !== -1 || p === "/data/adb" ||
                p.indexOf("ksu") !== -1 || p === "/nix") {
                return false;
            }
            return this.exists.call(this);
        };
    } catch(e) {}

    try {
        var PM = Java.use("android.app.ApplicationPackageManager");
        PM.getPackageInfo.overload("java.lang.String", "int").implementation = function(pkg, f) {
            var hide = ["com.rifsxd.ksunext", "me.weishu.kernelsu", "com.topjohnwu.magisk"];
            for (var i = 0; i < hide.length; i++) {
                if (pkg === hide[i]) {
                    throw Java.use("android.content.pm.PackageManager$NameNotFoundException").$new(pkg);
                }
            }
            return this.getPackageInfo(pkg, f);
        };
    } catch(e) {}

    try {
        var CertPinner = Java.use("okhttp3.CertificatePinner");
        CertPinner.check.overload("java.lang.String", "java.util.List").implementation = function() { return; };
        console.log("[+] OkHttp SSL pinning bypassed");
    } catch(e) {}

    console.log("[+] Java root/package bypass active");
});
}, 1000);

console.log("[*] Shopee bypass loaded — all hooks active");

var ticks = 0;
setInterval(function() {
    ticks += 5;
    send({type: "status", alive: ticks, threads: Process.enumerateThreads().length});
}, 5000);
