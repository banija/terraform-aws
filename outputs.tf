output "webserver_public_ip" {
    value = aws_eip.webserver.public_ip
}