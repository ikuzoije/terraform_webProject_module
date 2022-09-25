#!/usr/bin/env bash
yum -y update
yum -y install httpd
MYIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)


cat <<EOF > /var/www/html/index.html
<html>
<h2>Built by Power of <font color="red">Terraform</font></h2><br>

Server Owner is: ${f_name} ${l_name} <br>

<br>
PrivateIP: $MYIP

<br>
%{ for x in names ~}
Hello to ${x} from ${f_name}<br>
%{ endfor ~}

<br>
<p>
<font color="blue">Version 2.0</font>
</html>
EOF


service httpd start
chkconfig httpd on