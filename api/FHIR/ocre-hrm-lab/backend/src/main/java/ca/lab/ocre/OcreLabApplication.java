package ca.lab.ocre;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.amqp.rabbit.annotation.EnableRabbit;

@SpringBootApplication
@EnableRabbit
public class OcreLabApplication {
  public static void main(String[] args) { SpringApplication.run(OcreLabApplication.class, args); }
}
