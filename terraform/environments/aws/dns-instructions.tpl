DNS SETUP INSTRUCTIONS FOR ${domain}
========================================

Public IP Address: ${public_ip}

%{ if create_route53_zone }
Route53 Hosted Zone Created
----------------------------

Nameservers for delegation:
%{ for ns in nameservers ~}
  - ${ns}
%{ endfor ~}

ACTION REQUIRED:
1. Go to your domain registrar (Namecheap)
2. Update the nameservers for ${domain} to the ones listed above
3. Wait for DNS propagation (typically 15-30 minutes, can be up to 48 hours)

To verify propagation:
  dig NS ${domain}
  dig ${domain}

%{ else }
Manual DNS Configuration (Namecheap)
------------------------------------

Since you're using an external DNS provider, add these records at your registrar:

Required Records:
-----------------

1. A Record (Root):
   Host:  @
   Value: ${public_ip}
   TTL:   300 (or Automatic)

2. A Record (Wildcard):
   Host:  *
   Value: ${public_ip}
   TTL:   300

3. A Record (NS1):
   Host:  ns1
   Value: ${public_ip}
   TTL:   300

4. NS Record (Self-referencing):
   Host:  @
   Value: ns1.${domain}
   TTL:   300

Note: Some registrars may require you to create the A record for ns1 before
      allowing you to create the NS record pointing to it.

Verification Commands:
----------------------
After DNS propagation:
  dig ${domain}
  dig test.${domain}
  dig ns1.${domain}
  dig @${public_ip} test.${domain}

Expected Results:
  - ${domain} should resolve to ${public_ip}
  - *.${domain} should resolve to ${public_ip}
  - ns1.${domain} should resolve to ${public_ip}
  - Direct DNS query to server should work (after ansible run)

%{ endif }

Let's Encrypt Requirements:
----------------------------
For Let's Encrypt certificates to work:
- Domain must be publicly resolvable
- Ports 80 and 443 must be accessible
- Wait for full DNS propagation before running ansible

Test DNS propagation from multiple locations:
  https://dnschecker.org/#A/${domain}

Once DNS is working, proceed with Ansible deployment:
  cd ../../../ansible
  ansible-playbook -i inventory/aws playbooks/deploy-aws.yml