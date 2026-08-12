{ lib, pkgs, ... }:
{
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    openFirewall = true;

    settings = {
      http = {
        address = "0.0.0.0:3000";
      };

      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;

        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.google/dns-query"
          "tls://1dot1dot1dot1.cloudflare-dns.com"
        ];

        bootstrap_dns = [
          "1.1.1.1"
          "8.8.8.8"
          "9.9.9.9"
        ];

        enable_dnssec = true;
        ratelimit = 300;
        cache_size = 10000000;
        cache_ttl_min = 300;
        cache_ttl_max = 86400;
        cache_optimistic = true;
      };

      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt";
          name = "Peter Lowe - Adservers";
          id = 3;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_4.txt";
          name = "Dan Pollock's List";
          id = 4;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt";
          name = "Dandelion Sprout - Anti-Malware List";
          id = 6;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt";
          name = "Perflyst - Smart-TV Blocklist";
          id = 7;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_23.txt";
          name = "Game Console Adblock List";
          id = 23;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt";
          name = "Steven Black - Unified hosts";
          id = 33;
        }
      ];
    };
  };
}
