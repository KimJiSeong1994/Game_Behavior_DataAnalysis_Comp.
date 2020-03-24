# ================================== [ Data Pre-processing ] ===================================
library(tidyverse); library(data.table); library(dummies)
setwd("/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp.")
test = fread("./data/test.csv", header = T, sep = ",", encoding = "UTF-8")

test %>% 
  select(-event_contents) %>% 
  mutate(event_Ability = ifelse(event == "Ability", 1, 0),
         event_AddToControlGroup = ifelse(event == "AddToControlGroup", 1, 0),
         event_Camera = ifelse(event == "Camera", 1, 0),
         event_ControlGroup = ifelse(event == "ControlGroup", 1, 0),
         event_GetControlGroup = ifelse(event == "GetControlGroup", 1, 0),
         event_RightClick = ifelse(event == "Right Click", 1, 0),
         event_Selection = ifelse(event == "Selection", 1, 0),
         event_SetControlGroup = ifelse(event == "SetControlGroup", 1, 0)) -> test

test %>% 
  filter(player == 1) %>% 
  group_by(game_id) %>% 
  summarise(P1_species = unique(species),
            P1_Ability = sum(event_Ability),
            P1_AddToControlGroup = sum(event_AddToControlGroup),
            P1_Camera = sum(event_Camera),
            P1_ControlGroup = sum(event_ControlGroup),
            P1_GetControlGroup = sum(event_GetControlGroup),
            P1_RightClick = sum(event_RightClick),
            P1_Selection = sum(event_Selection),
            P1_SetControlGr6oup = sum(event_SetControlGroup)) -> test_P1

test %>% 
  filter(player == 0) %>% 
  group_by(game_id) %>% 
  summarise(time = max(time),
            P0_species = unique(species),
            P0_Ability = sum(event_Ability),
            P0_AddToControlGroup = sum(event_AddToControlGroup),
            P0_Camera = sum(event_Camera),
            P0_ControlGroup = sum(event_ControlGroup),
            P0_GetControlGroup = sum(event_GetControlGroup),
            P0_RightClick = sum(event_RightClick),
            P0_Selection = sum(event_Selection),
            P0_SetControlGr6oup = sum(event_SetControlGroup)) -> test_P0

tidy_test <- left_join(test_P0, test_P1, by = "game_id")

tidy_test %>% 
  mutate(diff_Ability = P1_Ability - P0_Ability,
         diff_AddToControlGroup = P1_AddToControlGroup - P0_AddToControlGroup,
         diff_Camera = P1_Camera - P0_Camera,
         diff_ControlGroup = P1_ControlGroup - P0_ControlGroup,
         diff_GetControlGroup = P1_GetControlGroup - P0_GetControlGroup,
         diff_RightClick = P1_RightClick - P0_RightClick,
         diff_Selection = P1_Selection - P0_Selection,
         diff_SetControlGr6oup = P1_SetControlGr6oup - P0_SetControlGr6oup) -> tidy_test

tidy_test %>% 
  mutate(P0_species = case_when(P0_species == "T" ~ 1,
                                P0_species == "P" ~ 2,
                                P0_species == "Z" ~ 3),
         P1_species = case_when(P1_species == "T" ~ 1,
                                P1_species == "P" ~ 2,
                                P1_species == "Z" ~ 3)) -> tidy_test

x_test <- tidy_test

## + [ build count Ability ] =================
test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Build")) %>% 
  group_by(game_id, player) %>% 
  summarise(P1_Build_building = n()) %>% 
  filter(player == 1) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Build")) %>% 
  group_by(game_id, player) %>% 
  summarise(P0_Build_building = n()) %>% 
  filter(player == 0) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

x_test %>% 
  map_dfc(function(x) str_replace_na(x, 0)) %>% 
  map_dfc(function(x) as.numeric(x)) %>% 
  mutate(diff_build_building = P1_Build_building - P0_Build_building) -> x_test

## + [ train unit Ability ] =================
## ++ [ worker unit ] =======================
worker_unit <- c("SCV", "Probe", "Drone")

test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Train")) %>% 
  filter(str_detect(event_contents, worker_unit)) %>% 
  group_by(game_id, player) %>% 
  summarise(P0_train_worker = n()) %>% 
  filter(player == 0) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Train")) %>% 
  filter(str_detect(event_contents, worker_unit)) %>% 
  group_by(game_id, player) %>% 
  summarise(P1_train_worker = n()) %>% 
  filter(player == 1) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

x_test %>% 
  map_dfc(function(x) str_replace_na(x, 0)) %>% 
  map_dfc(function(x) as.numeric(x)) %>%
  mutate(diif_train_worker = P1_train_worker - P0_train_worker) -> x_test


## ++ [ Train units ] ======================
test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Train")) %>% 
  group_by(game_id, player) %>% 
  summarise(P0_train_units = n()) %>% 
  filter(player == 0) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Train")) %>% 
  group_by(game_id, player) %>% 
  summarise(P1_train_units = n()) %>% 
  filter(player == 1) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

x_test %>% 
  map_dfc(function(x) str_replace_na(x, 0)) %>% 
  map_dfc(function(x) as.numeric(x)) %>%
  mutate(diif_train_units = P1_train_units - P0_train_units) -> x_test

## + [ Attact action ] ===============
test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Attack")) %>% 
  group_by(game_id, player) %>% 
  summarise(P1_Attack_count = n()) %>% 
  filter(player == 1) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Attack")) %>% 
  group_by(game_id, player) %>% 
  summarise(P0_Attack_count = n()) %>% 
  filter(player == 0) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

x_test %>% 
  map_dfc(function(x) str_replace_na(x, 0)) %>% 
  map_dfc(function(x) as.numeric(x)) %>%
  mutate(diff_Attack_count = P1_Attack_count - P0_Attack_count) -> x_test

## + [ Aboility Upgrade ] ===============
## ++ [ Attack ] ========================
attact_upgrade <- c("ShipWeapons", "InfantryWeapons", "GroundWeapons", "AirWeapons", "MeleeAttacks", 
                    "MissileAttacks", "FlyerAttacks")
test %>% 
  filter(player == 0 &str_detect(event_contents, attact_upgrade)) %>% 
  group_by(game_id,  player) %>% 
  summarise(attact_upgrade = n(),
            attact_upgrade = sum(attact_upgrade)) %>% 
  rename("P0_attact_upgrade" = attact_upgrade) %>% 
  select(-player) %>% 
  left_join(x_test, ., by = "game_id") -> x_test

test %>% 
  filter(player == 1 &str_detect(event_contents, attact_upgrade)) %>% 
  group_by(game_id,  player) %>% 
  summarise(attact_upgrade = n(),
            attact_upgrade = sum(attact_upgrade)) %>% 
  rename("P1_attact_upgrade" = attact_upgrade) %>% 
  select(-player) %>% 
  left_join(x_test, ., by = "game_id") -> x_test

x_test %>% 
  map_dfc(function(x) str_replace_na(x, 0)) %>% 
  map_dfc(function(x) as.numeric(x)) %>%
  mutate(diff_Attack_upgrade = P1_attact_upgrade - P0_attact_upgrade) -> x_test


## ++ [ defense Upgrade ] ================
defense_upgrad <- c("InfantryArmor", "VehicleandShipPlating", "GroundArmor", "Shields", "AirArmor", "GroundCarapace", "FlyerCarapace")

test %>% 
  filter(player == 0 &str_detect(event_contents, defense_upgrad)) %>% 
  group_by(game_id,  player) %>% 
  summarise(defense_upgrad = n(),
            defense_upgrad = sum(defense_upgrad)) %>% 
  rename("P0_defense_upgrad" = defense_upgrad) %>% 
  select(-player) %>% 
  left_join(x_test, ., by = "game_id") -> x_test

test %>% 
  filter(player == 1 &str_detect(event_contents, defense_upgrad)) %>% 
  group_by(game_id,  player) %>% 
  summarise(defense_upgrad = n(),
            defense_upgrad = sum(defense_upgrad)) %>% 
  rename("P1_defense_upgrad" = defense_upgrad) %>% 
  select(-player) %>% 
  left_join(x_test, ., by = "game_id") -> x_test

x_test %>% 
  map_dfc(function(x) str_replace_na(x, 0)) %>% 
  map_dfc(function(x) as.numeric(x)) %>%
  mutate(diff_defense_upgrade = P1_defense_upgrad - P0_defense_upgrad) -> x_test

x_test %>% 
  write.csv(., "tidy_test.csv")


