#############################################################
# Load Balancer for Kafka nodes
#############################################################
resource "aws_elb" "kafka" {
  name               = "kafka-elb-${var.env}"
  subnets            = "${aws_subnet.main.*.id}"
  security_groups    = []"${aws_security_group.kafka.id}"]
  internal           = true
  access_logs {
    bucket        	= "logs"
    enabled 		= false
  }

  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 9092
    instance_protocol = "tcp"
    lb_port           = 9092
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 9093
    instance_protocol = "tcp"
    lb_port           = 9093
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 9094
    instance_protocol = "tcp"
    lb_port           = 9094
    lb_protocol       = "tcp"
  }
  listener {
    instance_port     = 9095
    instance_protocol = "tcp"
    lb_port           = 9095
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:9092"
    interval            = 10
  }

  instances                   = "${aws_instance.kafka.*.id}"
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags  = {
    Name = "kafka-elb.${var.env}.${var.domain}"
  }
}

#############################################################
# Load Balancer for Zookeeper nodes
#############################################################
resource "aws_elb" "zookeeper" {
  name               = "zk-elb-${var.env}"
  subnets            = "${aws_subnet.main.*.id}"
  security_groups    = ["${aws_security_group.zookeeper.id}"]
  internal           = true

  access_logs {
     bucket        	= "logs"
     enabled 		= false
  }

  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 2181
    instance_protocol = "tcp"
    lb_port           = 2181
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:2181"
    interval            = 10
  }

  instances                   = "${aws_instance.zookeeper.*.id}"
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags  = {
    Name = "zk-elb.${var.env}.${var.domain}"
  }
}
