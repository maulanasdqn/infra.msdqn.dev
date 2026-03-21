{ shopee-tw, pkgs, ... }:
{
  services.shopee-scraper = {
    enable = true;
    package = shopee-tw.packages.${pkgs.system}.shopee-server;
    port = 3010;
    logLevel = "info";
    maxConcurrentPages = 3;
    requestTimeoutSecs = 45;
    retryAttempts = 3;
    useRemoteChrome = true;
    chromeDebugPort = 9222;
  };
}
