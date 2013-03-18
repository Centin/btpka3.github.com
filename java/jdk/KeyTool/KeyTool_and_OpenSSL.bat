REM ������ǩ�� CA ֤��
REM Win32 OpenSSL 
REM     http://slproweb.com/products/Win32OpenSSL.html
REM How to create a self-signed SSL Certificate
REM     http://www.akadia.com/services/ssh_test_certificate.html
REM OpenSSL to Keytool Conversion tips
REM     http://conshell.net/wiki/index.php/OpenSSL_to_Keytool_Conversion_tips
REM X.509
REM     http://en.wikipedia.org/wiki/X.509#Certificate_filename_extensions


REM ===================================== OpenSSL 2 KeyTools

REM 0. һ�������������ǩ���� CA ֤��
REM openssl req -x509 -newkey rsa:1024 -passout pass:123456 -days 3650 -keyout whhit.pem.key -out whhit.pem.cer -subj "/CN=whhit.me/OU=WeRun Club/O=whhit/L=Weihai/S=Shandong/C=CN"

REM 1. ����һ���µ�˽Կ
openssl genrsa -des3 -out whhit.pem.key -passout pass:123456 1024

REM 2. ʹ��ָ����˽Կ����һ��CSR (Certificate Signing Request)
openssl req -new -key whhit.pem.key -passin pass:123456 -out whhit.pem.csr -subj "/CN=whhit.me/OU=WeRun Club/O=whhit/L=Weihai/S=Shandong/C=CN"

REM 3. �����ܵ�˽Կ����Ϊ���ĵ�˽Կ
openssl rsa -in whhit.pem.key -passin pass:123456 -out whhit.pem.clear.key

REM 4. ʹ��ָ����˽Կǩ������֤��
openssl x509 -req -days 3650 -in whhit.pem.csr -signkey whhit.pem.clear.key -out whhit.pem.cer

REM 5. ��˽Կ��֤��ת��Ϊ PKCS#12 ��ʽ�ĵ����ļ�
openssl pkcs12 -export -in whhit.pem.cer -inkey whhit.pem.key -passin pass:123456 -out whhit.p12 -passout pass:123456 -name tomcat

REM 6. ʹ�� KeyTools �� PKSC#12 �ļ�����Ϊ JKS �� KeyStore
keytool -importkeystore -srcstoretype PKCS12 -srckeystore whhit.p12 -srcstorepass 123456 -srcalias tomcat -srckeypass 123456 -deststoretype JKS -destkeystore whhit.jks -deststorepass 123456 -destalias tomcat -destkeypass 123456


REM ===================================== KeyTools 2 OpenSSL

REM 1. ����һ������ǩ�� CA ֤��� JKS ���͵� KeyStore
keytool -genkeypair -alias tomcat -keyalg RSA -keysize 1024 -sigalg SHA1withRSA -dname "CN=test.me, OU=R & D department, O=\"BJ SOS Software Tech  Co., Ltd\", L=Beijing, S=Beijing, C=CN" -validity 3650 -keypass 123456 -keystore sos.jks -storepass 123456

REM 2. �� KeyStore �е���֤��
REM keytool -exportcert -rfc -file sos.pem.cer -alias tomcat -keystore sos.jks -storepass 123456

REM 3. �� KeyStore ���Ϊ PKCS#12 ��ʽ
keytool -importkeystore -srcstoretype JKS -srckeystore sos.jks -srcstorepass 123456 -srcalias tomcat -srckeypass 123456 -deststoretype PKCS12 -destkeystore sos.p12 -deststorepass 123456 -destalias tomcat -destkeypass 123456 -noprompt

REM 4. ʹ�� OpenSSL ���� PKCS#12 ��ʽ�� KeyStore����ת��Ϊ PEM ��ʽ(����֤���˽Կ)
openssl pkcs12 -in sos.p12 -out sos.pem.p12 -passin pass:123456 -passout pass:123456

REM 5. �������˽Կ�͹�Կ
openssl rsa -in sos.pem.p12 -passin pass:123456 -out sos.pem.key -passout pass:123456
openssl rsa -in sos.pem.p12 -passin pass:123456 -out sos.pem.pub -pubout

REM 6. �������֤��
openssl x509 -in sos.pem.p12 -out sos.pem.cer
