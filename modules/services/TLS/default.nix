# roadmap
#
# 1. implement config part:
#    - [done] where "ACME" creates a `security.acme` entry
#    - where "selfsigned" creates a self signed tls certificate
# 2. integrate this into nixcloud-webservices
#    - make nixcloud.TLS.certs."foo" a new option and check it properly
#    - test it with self signed certs
#    - test it with nixdoc.io ...
# 3. redo all description and examples
# 4. write a comprehensive nixcloud test for this
# 
#   nixcloud.TLS.certs = {
#     "example.com" = {
#       domain = "aaaaaaaaahhhhh.bb";
#       extraDomains = [ "flux.com" "flux.com" ];
#       mode = "ACME";
#       email = "foo@bar.com";
#       restart = [ "foo.service" "foo.service"];
#       reload =  [ "foo.service" "bar" ];
#     };
#     nixcloud.TLS.certs = {
#       "example.com" = {
#         domain = "aaaaaaaaahhhhh.bb";
#         extraDomains = [ "linux.org" ];
#         email = "foo@bar.com";
#         restart = [ "dovecot2.service" "foo.service" ];
#         reload = [ "foo.service" ];
#       };
#     };
#   };
#
# 5. release this to be used in nixcloud-webservices and nixcloud.email
# 6. blog about this new feature and give a short introduction into nix typing
#
#
# FIXME: blog post:
#  - example: see the https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/meta.nix example
#  - check: if check for custom type fails, one should be able to get a LOC string, where that type
#    was defined and what arguments it wants (as string for instance) and additionally one should
#    be able to supply a custom error message
#        error: The option value `nixcloud.TLS.certs.example.com.mode' in `/home/joachim/Desktop/projects/nixcloud/nixcloud-webservices/modules/services/TLS' is not of type `nixcloudTLSModeType'.
#    - this error message contains a BUG, as it states nixcloud.TLS.certs.example.com.mode instead of nixcloud.TLS.certs."example.com".mode
#    - custom types should have a name close to the type definition. in this example a user seeing this error message will get confused as
#      he does not know what is going on as he can't guess the internals
#    - that is why i hacked the name to be: `name = "nixcloud.TLS.certs.<name?>.mode";`
#  - check: in check one uses isString, it would be nice to also be able to use the same syntax as in
#    type = types.string (and similar functions) becase now one has to reimplement basically what we 
#    have in type already
#  - merge: explain `merge = loc: defs: ` with an easy example. especially point out builtins.trace and lib.traceVal usage ...
#  - merge: explain the bool merge vs. the string vs. the str merge (see domain/email option implications)
#  - merge: default values for mkOption(s) don't appear in the merge function arguments
#    - this means one can't easily add a domain name based on the 'submodule' functiosn 'name' argument as it won't appear
#      in the merge when some other module defines it.
#    - it also means that we can't bail out in the 'merge' function with an error: you forgot to define a meaningful value here
#      this is why nixcloud.TLS.certs.<name?>'s apply function has assertions for that (hack!)
#  - undefined values: in the option system produce this error:
#    error: The option `nixcloud.TLS.certs.example.com.mode' is used but not defined.
#    but it lacks a context where that 'usage' actually takes place
#  - explain: `apply = ` hack to assert that at last one module set this option
#
# idea: test if the check function can be used with `types.string.check`
#      || (types.string.check x && x == "ACME") 
#       and how this can be done with submodule and similar types
#
# wish: a hook for a custom type which is triggered once all modules have been merged so that
#       one can verify the state of a type before it is actually used
#       we could even call this assert?



# # motivation
# 
# nixcloud.TLS - an abstraction to configure TLS with ease
# 
# # links
# https://github.com/NixOS/nixpkgs/pull/34388
# 
# https://github.com/NixOS/nixpkgs/blob/release-18.03/nixos/modules/security/acme.nix
# 
# # requirements
# 
# * supported modes
#         * "selfsigned"
#         * "ACME"
#         * {tls_certificate_key = ./path/key.pem; tls_certificate = ./path/cert.pem }
# * reverse-proxy / nixcloud.email must wait until targets are ready, so 
#         nixcloud.TLS."nixcloud.io".systemd.before
#         nixcloud.TLS."nixcloud.io".systemd.wantedBy
# 
# # usage examples

## von irgendwo:

# nixcloud.TLS."example.com123" = {
#   domain = "example.com";
#   mode = "selfsigned";
# };
# 
# nixcloud.TLS."example.org" = {
#   mode = {
#     ssl_certificate_key = /path/to/cert.pem;
#     ssl_certificate = /path/to/key.pem;
#   };
# };
# 
# nixcloud.TLS."nixcloud.io".services =
#   {
#     postfix.action = "restart";
#     dovecot.action = "reload";
#   };
#   
# # später dann (um den merge zu zeigen):
# 
# nixcloud.TLS."nixcloud.io".services =
#   {
#     "nixcloud.reverse-proxy".action = "reload";
#   };
#   
# # when using the cert location:
# 
# config.nixcloud.TLS."nixcloud.io".ssl_certificate -> /path/to/cert.pem
# config.nixcloud.TLS."nixcloud.io".ssl_certificate_key -> /path/to/key.pem
# 
# # oder auch folgende idee:
# 
#   nixcloud.webservices.leaps.z2 = {
#     enable = true;
#     proxyOptions = {
#       port = 3031;
#       http.mode = "on";
#       https.mode = "on";
#       path = "/flubber99";
#       domain = "foo.com";
#       # mit eigenem cert
#       TLS = {
#         ssl_certificate_key = /path/to/cert.pem;
#         ssl_certificate = /path/to/key.pem;
#       };
#       # klassisch
#       TLS = "ACME"; 
#       # paul: wir nutzen immer nixcloud.TLS und übergeben nur den identifier
#       TLS = "example22.com"; -> ist doof weil wir zwischen "ACME" | "none" | "einer domain" unterscheiden müssen
#       # ist das ne gute syntax?
#       TLS = nixcloud.TLS."example22.com"; -> gewinner: wir haben entweder builtins.typeOf "string" oder "set"
#                                              und bei set schauen wir ob ssl_certificate / ssl_certificate_key gesetzt ist
#     };
#   };
# 

# https://trello.com/c/dHSQhPYx/180-nixcloudtls
{ config, pkgs, lib, ... } @ args:
with lib;

let
  cfg = config.nixcloud.TLS;
  stateDir = "/var/lib/nixcloud/TLS/";
  tls_certificateSetModule = {
    options = {
      tls_certificate = mkOption {
        type = types.path;
        description = ''
          A location containg the full path and filename to `/path/to/fullchain.pem`.
        '';
        example = "/path/to/fullchain.pem";
      };
      tls_certificate_key = mkOption {
        type = types.path;
        description = ''
          A location containg the full path and filename to `/path/to/key.pem`.
        '';
        example = "/path/to/key.pem";
      };
    };
  };
  nixcloudTLSDomainType = mkOptionType {
    name = "nixcloud.TLS.certs.<name?>.domain";
    check = x: (isString x && x != "") 
      || (isNull x);
    merge = mergeEqualOption;
  };
  nixcloudTLSEmailType = mkOptionType {
    name = "nixcloud.TLS.certs.<name?>.email";
    check = x: (isString x && x != "") 
      || (isNull x);
    merge = mergeEqualOption;
  };  
  nixcloudTLSModeType = mkOptionType {
    name = "nixcloud.TLS.certs.<name?>.mode";
    merge = mergeEqualOption;
    # FIXME this check is not 100% the same as the type previously was...
    # -> types.either (types.enum [ "ACME" "selfsigned" ]) (types.submodule tls_certificateSetModule);
    check = x: ((isString x && x == "ACME") 
        || (isString x && x == "selfsigned") 
        || ((isAttrs x || isFunction x) && x ? tls_certificate_key && x ? tls_certificate))
      || (isNull x);
  };
  c = x: ((isList x) && fold (el: c: if (isString el) then c else false) true x);
  m = loc: defs: unique (fold (el: c: el.value ++ c) [] defs);
  nixcloudExtraDomainsType = mkOptionType {
    name = "nixcloud.TLS.certs.<name?>.extraDomains";
    check = c;
    merge = m;
  };
  nixcloudReloadType = mkOptionType {
    name = "nixcloud.TLS.certs.<name?>.reload";
    check = c;
    merge = m;
  };
  nixcloudRestartType = mkOptionType {
    name = "nixcloud.TLS.certs.<name?>.restart";
    check = c;
    merge = m;
  };  
  certOpts = { name, ... } @ toplevel: {
    options = {
      domain = mkOption {
        type = nixcloudTLSDomainType;
        default = null;
        description = "Domain to fetch certificate for (defaults to the entry name)";
      };
      extraDomains = mkOption {
        type = nixcloudExtraDomainsType;
        default = [];
        example = literalExample ''
          [ "example.org" "mydomain.org" ];
        '';
        apply = x: unique x;
        description = ''
          A list of extra domain names, which are included in the one certificate to be issued, with their
          own server roots if needed.
        '';
      };
      reload = mkOption {
        type = nixcloudReloadType;
        apply = x: lib.subtractLists toplevel.config.restart (unique x);
        default = [];
        example = [ "postifx.service" ];
        description = ''
          A list of systemd services which are `reloaded` after certificates are re-issued.
          A service is only `reloaded` once, even when mentioned serveral times in this list.
          It is not reloaded if it is also listed in the `restart` list, then it is only restarted.
        '';
      };    
      restart = mkOption {
        type = nixcloudRestartType;
        default = [];
        apply = x: unique x;
        example = [ "postifx.service" ];
        description = ''
          A list of systemd services which are `restarted` after certificates are re-issued.
          A service is only `restarted` once, even when mentioned serveral times in this list.
        '';
      };  
      email = mkOption {
        type = nixcloudTLSEmailType;
        default = null;
        description = "Contact email address for the CA to be able to reach you when using ACME.";
      };
      mode = mkOption {
        type = nixcloudTLSModeType;
        default = null;
        description = ''
         Use this option to set the `TLS mode` to be used:
        
          * "ACME" - (default) uses let's encrypt to automatically download and install TLS certificates
          * "selfsigned" - this abstraction will create self signed certificates
          * { tls_certificate_key = /flux/to/cert.pem; tls_certificate = /flux/to/key.pem; }; - supply the certificates yourself
      ''; #'
 
      };
      tls_certificate_key = mkOption {
        type = types.path;
        readOnly = true;
        default = 
          if (isString toplevel.config.mode) then 
            if (toplevel.config.mode == "ACME") then "/var/lib/acme/${name}/tlskey.pem" else "/var/lib/nixcloud/TLS/${name}/tlskey.pem"
          else 
            "/";
        description = "";
      };
      tls_certificate = mkOption {
        type = types.path;
        readOnly = true;
        default = 
          if (isString toplevel.config.mode) then 
            if (toplevel.config.mode == "ACME") then "/var/lib/acme/${name}/tlscert.pem" else "/var/lib/nixcloud/TLS/${name}/tlscert.pem"
          else 
            "/";
        description = "";
      };        
    };
  };
in

{
  options = {
    nixcloud.TLS = {
      certs = mkOption {
        default = {};
        type = types.attrsOf (types.submodule certOpts);
        description = ''
          Attribute set of certificates to get signed and renewed.
        '';
        example = literalExample ''

        '';
      };
    };
  };
  
  config = let
    mkAssertion-Mode = cert: 
      { assertion = config.nixcloud.TLS.certs.${cert}.mode != null;
        message = ''
          Error: nixcloud.TLS.certs.${cert}.mode is not set correctly (it was 'null')!
        '';
      };
    mkAssertion-Domain = cert: 
      { assertion = config.nixcloud.TLS.certs.${cert}.domain != null;
        message = ''
          Error: nixcloud.TLS.certs.${cert}.domain is not set correctly (it was 'null')!
        '';
      };      
  in  {
    # make sure that `domain` and `mode` is set properly
    assertions = map (cert: mkAssertion-Mode   cert) (attrNames config.nixcloud.TLS.certs) ++
                 map (cert: mkAssertion-Domain cert) (attrNames config.nixcloud.TLS.certs);
  
    security.acme.certs = (fold (cert: con: if ((config.nixcloud.TLS.certs.${cert}.mode) == "ACME") then con // {
      "${cert}" = let c = config.nixcloud.TLS.certs.${cert}; in {
        domain = "${c.domain}";
        email = c.email;
        webroot = "/var/lib/acme/acme-challenges";
        postRun = ''
          ${lib.concatStringsSep "\n" (map (el: "systemctl restart ${el}") c.restart)}
          ${lib.concatStringsSep "\n" (map (el: "systemctl reload ${el}") c.reload)}
        '';
      };
    } else con) {} (attrNames config.nixcloud.TLS.certs));
  
  
    #systemd.targets."acme-selfsigned-certificates" = mkIf cfg.preliminarySelfsigned {};

    systemd.services."nixcloud.TLS" = let
        certs = config.nixcloud.TLS.certs;
        acmeIsUsed = fold (cert: con: (certs.${cert}.mode == "ACME") || con) false (attrNames certs);
        #     selfsignedService = {
#       description = "Create preliminary self-signed certificate for ${cert}";
#       preStart = ''
#           if [ ! -d '${cpath}' ]
#           then
#             mkdir -p '${cpath}'
#             chmod ${rights} '${cpath}'
#             chown '${data.user}:${data.group}' '${cpath}'
#           fi
#       '';
#       script = 
#         ''
#           # Create self-signed key
#           workdir="/run/acme-selfsigned-${cert}"
#           ${pkgs.openssl.bin}/bin/openssl genrsa -des3 -passout pass:x -out $workdir/server.pass.key 2048
#           ${pkgs.openssl.bin}/bin/openssl rsa -passin pass:x -in $workdir/server.pass.key -out $workdir/server.key
#           ${pkgs.openssl.bin}/bin/openssl req -new -key $workdir/server.key -out $workdir/server.csr \
#             -subj "/C=UK/ST=Warwickshire/L=Leamington/O=OrgName/OU=IT Department/CN=example.com"
#           ${pkgs.openssl.bin}/bin/openssl x509 -req -days 1 -in $workdir/server.csr -signkey $workdir/server.key -out $workdir/server.crt
#           # Move key to destination
#           mv $workdir/server.key ${cpath}/key.pem
#           mv $workdir/server.crt ${cpath}/fullchain.pem
#           # Create full.pem for e.g. lighttpd (same format as "simp_le ... -f full.pem" creates)
#           cat "${cpath}/key.pem" "${cpath}/fullchain.pem" > "${cpath}/full.pem"
#           # Clean up working directory
#           rm $workdir/server.csr
#           rm $workdir/server.pass.key
#           # Give key acme permissions
#           chmod ${rights} '${cpath}/key.pem'
#           chown '${data.user}:${data.group}' '${cpath}/key.pem'
#           chmod ${rights} '${cpath}/fullchain.pem'
#           chown '${data.user}:${data.group}' '${cpath}/fullchain.pem'
#           chmod ${rights} '${cpath}/full.pem'
#           chown '${data.user}:${data.group}' '${cpath}/full.pem'
#         '';
#       serviceConfig = {
#         Type = "oneshot";
#         RuntimeDirectory = "acme-selfsigned-${cert}";
#         PermissionsStartOnly = true;
#         User = data.user;
#         Group = data.group;
#       };
#       unitConfig = {
#         # Do not create self-signed key when key already exists
#         ConditionPathExists = "!${cpath}/key.pem";
#       };
#       before = [
#         "acme-selfsigned-certificates.target"
#       ];
#       wantedBy = [
#         "acme-selfsigned-certificates.target"
#       ];
#     };

#       mainScript = pkgs.writeText "main.sh" ''
#         #!/usr/bin/env bash
#         echo "tut";
#         exit 0
#       '';
    in {
      description   = "nixcloud.TLS service (managing TLS certificates)";
      wantedBy      = [ "multi-user.target" ];
      
      after = if acmeIsUsed then [ "acme-selfsigned-certificates.target" ] else [ "network.target" ] 
                ++ [ "nixcloud.TLS-selfsigned-certificates.target" ];
      wants =  if acmeIsUsed then [ "acme-selfsigned-certificates.target" "acme-certificates.target" ] else [] 
                ++ [ "nixcloud.TLS-selfsigned-certificates.target" ];

      #before = [ "nixcloud.TLS-acme-certificates.target" ];
      #wantedBy = [ "nixcloud.TLS-acme-certificates.target" ];
        
      preStart = ''
        mkdir -p ${stateDir}
        # we only need to apply this to the certifictes itself, not the top level dir, see /var/lib/acme
        #chmod 0700 ${stateDir}
      '';

      serviceConfig = {
        ExecStart = "${pkgs.bash}/bin/bash -c 'exit 0;'";
        RemainAfterExit=true;
      };
    };
  meta = {
    maintainers = with lib.maintainers; [ qknight ];
  };
  
  #nixcloud.tests.wanted = [ ./test.nix ];
};

}


 