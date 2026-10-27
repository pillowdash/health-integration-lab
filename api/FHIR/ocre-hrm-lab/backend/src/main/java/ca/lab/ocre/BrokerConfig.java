package ca.lab.ocre;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class BrokerConfig {
  public static final String EXCHANGE = "ocre.lab.reports";
  public static final String QUEUE = "ocre.lab.dispatch";
  @Bean TopicExchange reportsExchange() { return new TopicExchange(EXCHANGE, true, false); }
  @Bean Queue reportsQueue() { return new Queue(QUEUE, true); }
  @Bean Binding reportBinding(Queue reportsQueue, TopicExchange reportsExchange) {
    return BindingBuilder.bind(reportsQueue).to(reportsExchange).with("report.#");
  }
}
