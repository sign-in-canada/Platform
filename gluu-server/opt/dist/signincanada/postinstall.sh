#!/bin/sh

echo 'Stopping services...'
systemctl stop httpd oxauth identity idp passport

echo 'Enabling the keyvault service...'
if grep Red /etc/redhat-release ; then
   yum remove -y epel-release
fi
yum clean all
yum install -y jq
systemctl enable keyvault

echo 'Enabling the couchbase health check service...'
systemctl enable cbcheck

echo "Enabling the passport key extraction service"
systemctl enable passportkeys

echo 'Installing the Application Insights SDK to oxAuth...'
install -m 644 -o jetty -g jetty /opt/dist/signincanada/applicationinsights-core-2.6.3.jar /opt/gluu/jetty/oxauth/custom/libs
if [ -d /opt/gluu/jetty/idp ] ; then
   echo 'Installing custom libs into Shibboleth...'
   install -m 755 -o jetty -g jetty -d /opt/gluu/jetty/idp/custom/libs
   install -m 644 -o jetty -g jetty /opt/dist/signincanada/shib-oxauth-authn3-4.2.3.sic1.jar /opt/gluu/jetty/idp/custom/libs
   install -m 644 -o jetty -g jetty /opt/dist/signincanada/applicationinsights-core-2.6.3.jar /opt/gluu/jetty/idp/custom/libs
fi

mkdir -p /tmp/patch/WEB-INF/lib
echo 'Updating the Couchbase client...'
cp /opt/dist/app/core-io-1.7.22.jar /tmp/patch/WEB-INF/lib
cp /opt/dist/app/java-client-2.7.22.jar /tmp/patch/WEB-INF/lib
pushd /tmp/patch 2>&1
zip -d /opt/gluu/jetty/oxauth/webapps/oxauth.war \
   WEB-INF/lib/core-io-1.7.16.jar \
   WEB-INF/lib/java-client-2.7.16.jar
zip -u /opt/gluu/jetty/oxauth/webapps/oxauth.war  \
   WEB-INF/lib/java-client-2.7.22.jar \
   WEB-INF/lib/core-io-1.7.22.jar
zip -d /opt/gluu/jetty/identity/webapps/identity.war \
   WEB-INF/lib/core-io-1.7.16.jar \
   WEB-INF/lib/java-client-2.7.16.jar
zip -u /opt/gluu/jetty/identity/webapps/identity.war \
   WEB-INF/lib/java-client-2.7.22.jar \
   WEB-INF/lib/core-io-1.7.22.jar
if [ -d /opt/gluu/jetty/idp ] ; then
   zip -qd /opt/gluu/jetty/idp/webapps/idp.war \
      WEB-INF/lib/core-io-1.7.16.jar \
      WEB-INF/lib/java-client-2.7.16.jar
   zip -qu /opt/gluu/jetty/idp/webapps/idp.war \
      WEB-INF/lib/java-client-2.7.22.jar \
      WEB-INF/lib/core-io-1.7.22.jar
fi
popd > /dev/null 2>&1

echo 'Updating log4j'
cp /opt/dist/app/log4j-api-2.17.1.jar /tmp/patch/WEB-INF/lib
cp /opt/dist/app/log4j-core-2.17.1.jar /tmp/patch/WEB-INF/lib
cp /opt/dist/app/log4j-jul-2.17.1.jar /tmp/patch/WEB-INF/lib
cp /opt/dist/app/log4j-over-slf4j-1.7.32.jar /tmp/patch/WEB-INF/lib
cp /opt/dist/app/log4j-slf4j-impl-2.17.1.jar /tmp/patch/WEB-INF/lib
pushd /tmp/patch 2>&1
zip -d /opt/gluu/jetty/oxauth/webapps/oxauth.war \
   WEB-INF/lib/log4j-api-2.13.3.jar \
   WEB-INF/lib/log4j-1.2-api-2.13.3.jar \
   WEB-INF/lib/log4j-core-2.13.3.jar \
   WEB-INF/lib/log4j-slf4j-impl-2.13.3.jar \
   WEB-INF/lib/log4j-jul-2.13.3.jar
zip -u /opt/gluu/jetty/oxauth/webapps/oxauth.war  \
   WEB-INF/lib/log4j-api-2.17.1.jar \
   WEB-INF/lib/log4j-1.2-api-2.17.1.jar \
   WEB-INF/lib/log4j-core-2.17.1.jar \
   WEB-INF/lib/log4j-slf4j-impl-2.17.1.jar \
   WEB-INF/lib/log4j-jul-2.17.1.jar
zip -d /opt/gluu/jetty/identity/webapps/identity.war \
   WEB-INF/lib/log4j-api-2.13.3.jar \
   WEB-INF/lib/log4j-1.2-api-2.13.3.jar \
   WEB-INF/lib/log4j-core-2.13.3.jar \
   WEB-INF/lib/log4j-jul-2.13.3.jar
zip -u /opt/gluu/jetty/identity/webapps/identity.war  \
   WEB-INF/lib/log4j-api-2.17.1.jar \
   WEB-INF/lib/log4j-1.2-api-2.17.1.jar \
   WEB-INF/lib/log4j-core-2.17.1.jar \
   WEB-INF/lib/log4j-jul-2.17.1.jar
if [ -d /opt/gluu/jetty/idp ] ; then
   zip -d /opt/gluu/jetty/idp/webapps/idp.war \
      WEB-INF/lib/log4j-api-2.13.3.jar \
      WEB-INF/lib/log4j-1.2-api-2.13.3.jar \
      WEB-INF/lib/log4j-core-2.13.3.jar \
      WEB-INF/lib/log4j-over-slf4j-1.7.30.jar
   zip -u /opt/gluu/jetty/idp/webapps/idp.war  \
      WEB-INF/lib/log4j-api-2.17.1.jar \
      WEB-INF/lib/log4j-1.2-api-2.17.1.jar \
      WEB-INF/lib/log4j-core-2.17.1.jar \
      WEB-INF/lib/log4j-over-slf4j-1.7.32.jar
fi
popd > /dev/null 2>&1

echo 'Installing the UI...'
tar xzf /opt/dist/signincanada/custom.tgz -C /opt/gluu/jetty/oxauth/custom
chown -R jetty:jetty /opt/gluu/jetty/oxauth/custom
chmod 755 $(find /opt/gluu/jetty/oxauth/custom -type d -print)
chmod 644 $(find /opt/gluu/jetty/oxauth/custom -type f -print)

echo 'Installing the Notify service...'
mkdir -p /opt/gluu/node/gc/notify/logs
tar xzf /opt/dist/signincanada/node-services.tgz -C /opt/gluu/node/gc/notify
chown -R node:node /opt/gluu/node/gc
cp /opt/dist/signincanada/notify-config.json /etc/gluu/conf
systemctl enable notify

echo 'Removing unused Gluu authentication pages...'
zip -d -q /opt/gluu/jetty/oxauth/webapps/oxauth.war "/auth/*"

if [ -d /opt/shibboleth-idp/conf ] ; then
   echo 'Configuring Shibboleth...'
   install  -m 444 -o jetty -g jetty /opt/dist/signincanada/shibboleth-idp/conf/*.xml /opt/shibboleth-idp/conf
   install  -m 644 -o jetty -g jetty /opt/dist/signincanada/shibboleth-idp/conf/*.js /opt/shibboleth-idp/conf
   install  -m 644 -o jetty -g jetty /opt/dist/signincanada/shibboleth-idp/conf/authn/*.xml /opt/shibboleth-idp/conf/authn
fi

echo "Configuring httpd chain certificate..."
sed -i "17i\ \ \ \ \ \ \ \ SSLCertificateChainFile /etc/certs/httpd.chain" /etc/httpd/conf.d/https_gluu.conf

echo "Updating packages..."
yum update -y
echo 'Done.'
