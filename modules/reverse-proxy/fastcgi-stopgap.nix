# Traefik doesn't support FastCGI https://github.com/traefik/traefik/issues/9521
# This means that languages that heavily rely on FastCGI like PHP don't work
# with it. As a stopgap, we run another HTTP server (Nginx) which supports
# FastCGI. So the traffic goes: traefik -> nginx -> {fastcgi server} -> {app}
{...}: {
  services.nginx = {
    enable = true;
    defaultListenAddresses = ["127.0.0.1"];
  };
}
