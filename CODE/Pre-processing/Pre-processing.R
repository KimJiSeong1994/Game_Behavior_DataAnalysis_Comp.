# ================================== [ Data Pre-processing ] ===================================
library(tidyverse); library(data.table); library(dummies)

train = fread("/data/train.csv", header = T, sep = ",", encoding = "UTF-8")
train %>% 
  dummy.data.frame(names = "event", sep = "_") -> train # one-hot vector

train %>% 
  filter(player == 1) %>% 
  group_by(game_id) %>% 
  summarise(P1_species = unique(species),
            P1_Ability = sum(event_Ability),
            P1_AddToControlGroup = sum(event_AddToControlGroup),
            P1_Camera = sum(event_Camera),
            P1_ControlGroup = sum(event_ControlGroup),
            P1_GetControlGroup = sum(event_GetControlGroup),
            P1_RightClick = sum(`event_Right Click`),
            P1_Selection = sum(event_Selection),
            P1_SetControlGr6oup = sum(event_SetControlGroup),
            winner = unique(winner)) -> p1

train %>% 
  filter(player == 0) %>% 
  group_by(game_id) %>% 
  summarise(time = max(time),
            P0_species = unique(species),
            P0_Ability = sum(event_Ability),
            P0_AddToControlGroup = sum(event_AddToControlGroup),
            P0_Camera = sum(event_Camera),
            P0_ControlGroup = sum(event_ControlGroup),
            P0_GetControlGroup = sum(event_GetControlGroup),
            P0_RightClick = sum(`event_Right Click`),
            P0_Selection = sum(event_Selection),
            P0_SetControlGr6oup = sum(event_SetControlGroup)) -> p0 

tidy_train <- left_join(p0, p1, by = "game_id")

tidy_train %>% 
  mutate(diff_Ability = P1_Ability - P0_Ability,
         diff_AddToControlGroup = P1_AddToControlGroup - P0_AddToControlGroup,
         diff_Camera = P1_Camera - P0_Camera,
         diff_ControlGroup = P1_ControlGroup - P0_ControlGroup,
         diff_GetControlGroup = P1_GetControlGroup - P0_GetControlGroup,
         diff_RightClick = P1_RightClick - P0_RightClick,
         diff_Selection = P1_Selection - P0_Selection,
         diff_SetControlGr6oup = P1_SetControlGr6oup - P0_SetControlGr6oup) %>% 
  select(1:29, winner) -> tidy_train

x_train <- tidy_train[, names(tidy_train) != "winner"]
y_train <- tidy_train[, "winner"]