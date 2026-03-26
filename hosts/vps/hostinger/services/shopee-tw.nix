{ shopee-tw, pkgs, ... }:
{
  services.shopee-scraper = {
    enable = true;
    package = shopee-tw.packages.${pkgs.system}.shopee-server;
    port = 3010;
    logLevel = "info";
    maxConcurrentPages = 3;
    requestTimeoutSecs = 90;
    retryAttempts = 3;
    useRemoteChrome = true;
    chromeDebugPort = 9222;
    proxyHost = "us.novproxy.io:1000";
    proxyUser = "v3m554323-region-TW";
    proxyPass = "zqh6qliz";
    shopeeEmail = "msdqn@outlook.com";
    shopeePassword = "EtTGCGN4qZM!";
    socks5ProxyUrl = "socks5://127.0.0.1:1080";
  };
}
