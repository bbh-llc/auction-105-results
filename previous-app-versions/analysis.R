#state analysis

revenue_by_state <- states_sf_5g %>% 
  group_by(State) %>% 
  summarise(total_money_raised = sum(posted_price),
    total_population = sum(population)) %>%
  mutate(per_head_price = total_money_raised/total_population)
