output "public_ip"    { value = aws_instance.jenkins.public_ip }
output "instance_id"  { value = aws_instance.jenkins.id }
output "key_name"     { value = aws_key_pair.jenkins.key_name }
