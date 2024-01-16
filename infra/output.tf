
output "ecs_vpc_id" {
  value = module.vpc.vpc_id
}

output "dns_grafana" {
  value = aws_route53_record.grafana_record.name
}

output "dns_prometheus" {
  value = aws_route53_record.prometheus_record.name
}

output "dns_alertmanager" {
  value = aws_route53_record.alertmanager_record.name
}

