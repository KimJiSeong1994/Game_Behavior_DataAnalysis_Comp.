# ======================================= [ Data EDA ] ==========================================
library(tidyverse); library(data.table)
train = fread("/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./data/train.csv", header = T, sep = ",")

train %>% 
  filter(game_id == 100 & event == "Camera") %>% 
  mutate(event_contents = str_remove_all(event_contents, "\\(")) %>%
  mutate(event_contents = str_remove_all(event_contents, "\\)")) %>%
  mutate(event_contents = str_remove_all(event_contents, "[[a-z][A-Z]]")) %>%
  separate(event_contents, into = c("loc_x", "loc_y"), sep = ",\\s") %>%
  mutate(loc_x = as.numeric(loc_x),
         loc_y = as.numeric(loc_y)) %>% 
  ggplot(aes(x = loc_x, y = loc_y)) +
  geom_point(aes(col = factor(player)), alpha = 0.4, show.legend = F) +
  theme_bw()
  
