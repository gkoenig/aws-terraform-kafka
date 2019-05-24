resource "null_resource" "ssl" {
  provisioner "local-exec" {
    command = " mkdir ssl; cd ssl; openssl req -new -newkey rsa:4096 -days 3650 -x509 -subj \"/CN=Kafka CA\" -keyout ca-key -out ca-cert -nodes; keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert -storepass itergo -keypass itergo -noprompt; keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass itergo -keypass itergo -noprompt; keytool -genkey -keystore kafka.server.keystore.jks -alias localhost -validity 3650 -storepass itergo -keypass itergo  -dname \"CN=*.${var.env}.${var.domain}\"; keytool -keystore kafka.server.keystore.jks -alias localhost -certreq -file cert-file -storepass itergo -keypass itergo; openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 3650 -CAcreateserial -passin pass:itergo; keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert -storepass itergo -keypass itergo -noprompt; keytool -keystore kafka.server.keystore.jks -alias localhost -import -file cert-signed -storepass itergo -keypass itergo -noprompt; cd .. ; zip -r ssl.zip ssl"
  }
}

