# ================================== [ Data Pre-processing ] ===================================
library(tidyverse); library(data.table)
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
            P1_SetControlGroup = sum(event_SetControlGroup)) -> test_P1

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
            P0_SetControlGroup = sum(event_SetControlGroup)) -> test_P0

tidy_test <- left_join(test_P0, test_P1, by = "game_id")

tidy_test %>% 
  mutate(diff_Ability = P1_Ability - P0_Ability,
         diff_AddToControlGroup = P1_AddToControlGroup - P0_AddToControlGroup,
         diff_Camera = P1_Camera - P0_Camera,
         diff_ControlGroup = P1_ControlGroup - P0_ControlGroup,
         diff_GetControlGroup = P1_GetControlGroup - P0_GetControlGroup,
         diff_RightClick = P1_RightClick - P0_RightClick,
         diff_Selection = P1_Selection - P0_Selection,
         diff_SetControlGroup = P1_SetControlGroup - P0_SetControlGroup) -> tidy_test

tidy_test %>% 
  mutate(P0_species = case_when(P0_species == "T" ~ 1,
                                P0_species == "P" ~ 2,
                                P0_species == "Z" ~ 3),
         P1_species = case_when(P1_species == "T" ~ 1,
                                P1_species == "P" ~ 2,
                                P1_species == "Z" ~ 3)) -> tidy_test

# test = fread("./data/test.csv", header = T, sep = ",", encoding = "UTF-8")
tidy_test = fread("tidy_test.csv", header = T, sep = ",", encoding = "UTF-8")
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

## + [ UnitPd_building ] =====================
test %>% 
  filter(event == "Ability" & str_detect(event_contents, "BuildBarracks") | str_detect(event_contents, "BuildFactory") | str_detect(event_contents, "BuildStarport") | str_detect(event_contents, "BuildReactor") |
           str_detect(event_contents, "BuildHatchery") | 
           str_detect(event_contents, "BuildGateway") | str_detect(event_contents, "BuildStargate") | str_detect(event_contents, "BuildRoboticsFacility")) %>% 
  group_by(game_id, player) %>% 
  summarise(P1_Build_UnitPD_building = n()) %>% 
  filter(player == 1) %>% 
  left_join(x_test, .) %>% 
  select(-player) -> x_test

test %>% 
  filter(event == "Ability" & str_detect(event_contents, "BuildBarracks") | str_detect(event_contents, "BuildFactory") | str_detect(event_contents, "BuildStarport") | str_detect(event_contents, "BuildReactor") |
           str_detect(event_contents, "BuildHatchery") | 
           str_detect(event_contents, "BuildGateway") | str_detect(event_contents, "BuildStargate") | str_detect(event_contents, "BuildRoboticsFacility")) %>% 
  group_by(game_id, player) %>% 
  summarise(P0_Build_UnitPD_building = n()) %>% 
  filter(player == 0) %>% 
  left_join(x_test, .) %>% 
  select(-player) -> x_test

x_test %>% 
  mutate(P1_Build_UnitPD_building = str_replace_na(P1_Build_UnitPD_building, 0),
         P1_Build_UnitPD_building = as.numeric(P1_Build_UnitPD_building),
         P0_Build_UnitPD_building = str_replace_na(P0_Build_UnitPD_building, 0),
         P0_Build_UnitPD_building = as.numeric(P0_Build_UnitPD_building)) -> x_test  # 세분화 필요 (업글 / 병력생산)

## + [ Tech_building ] =====================
test %>% 
  filter(event == "Ability" & str_detect(event_contents, "BuildEvolutionChamber") | str_detect(event_contents, "BuildSpawningPool") | str_detect(event_contents, "BuildBanelingNest") | str_detect(event_contents, "BuildRoachWarren") | str_detect(event_contents, "BuildHydraliskDen") | str_detect(event_contents, "BuildSpire") | str_detect(event_contents, "BuildInfestationpit") | str_detect(event_contents, "BuildNydusNetwork") | str_detect(event_contents, "BuildGreaterSpire") | str_detect(event_contents, "BuildUltraliskCavern") |
           str_detect(event_contents, "BuildEngineeringBay") | str_detect(event_contents, "BuildGhostAcademy") | str_detect(event_contents, "BuildArmory") | str_detect(event_contents, "BuildFusionCore") | str_detect(event_contents, "BuildArmory") | str_detect(event_contents, "BuildBarracksTechLab") |
           str_detect(event_contents, "BuildForge") | str_detect(event_contents, "BuildCyberneticsCore") | str_detect(event_contents, "BuildTwilightCouncil") | str_detect(event_contents, "BuildRoboticsBay") | str_detect(event_contents, "BuildDarkShrine") | str_detect(event_contents, "BuildTemplarArchives") | str_detect(event_contents, "BuildFleetBeacon")) %>% 
  group_by(game_id, player) %>% 
  filter(player == 1) %>%
  summarise(P1_Build_Tech_building = n()) %>% 
  left_join(x_test, .) %>% 
  select(-player) -> x_test

test %>% 
  filter(event == "Ability" & str_detect(event_contents, "BuildEvolutionChamber") | str_detect(event_contents, "BuildSpawningPool") | str_detect(event_contents, "BuildBanelingNest") | str_detect(event_contents, "BuildRoachWarren") | str_detect(event_contents, "BuildHydraliskDen") | str_detect(event_contents, "BuildSpire") | str_detect(event_contents, "BuildInfestationpit") | str_detect(event_contents, "BuildNydusNetwork") | str_detect(event_contents, "BuildGreaterSpire") | str_detect(event_contents, "BuildUltraliskCavern") |
           str_detect(event_contents, "BuildEngineeringBay") | str_detect(event_contents, "BuildGhostAcademy") | str_detect(event_contents, "BuildArmory") | str_detect(event_contents, "BuildFusionCore") | str_detect(event_contents, "BuildArmory") | str_detect(event_contents, "BuildBarracksTechLab") |
           str_detect(event_contents, "BuildForge") | str_detect(event_contents, "BuildCyberneticsCore") | str_detect(event_contents, "BuildTwilightCouncil") | str_detect(event_contents, "BuildRoboticsBay") | str_detect(event_contents, "BuildDarkShrine") | str_detect(event_contents, "BuildTemplarArchives") | str_detect(event_contents, "BuildFleetBeacon")) %>% 
  group_by(game_id, player) %>% 
  filter(player == 0) %>%
  summarise(P0_Build_Tech_building = n()) %>% 
  left_join(x_test, .) %>% 
  select(-player) -> x_test

x_test %>% 
  mutate(P1_Build_Tech_building = str_replace_na(P1_Build_Tech_building, 0),
         P1_Build_Tech_building = as.numeric(P1_Build_Tech_building),
         P0_Build_Tech_building = str_replace_na(P0_Build_Tech_building, 0),
         P0_Build_Tech_building = as.numeric(P0_Build_Tech_building)) -> x_test

## + [ def_building ] =====================
test %>% 
  filter(event == "Ability" & str_detect(event_contents, "BuildSprineCrawler") | str_detect(event_contents, "BuildPlanetaryFortress") | 
           str_detect(event_contents, "BuildOrbitalCommand") | str_detect(event_contents, "BuildMissileTurret") | str_detect(event_contents, "BuildSensorTower") |str_detect(event_contents, "BuildBunker") |
           str_detect(event_contents, "BuildPhotonCannon")) %>% 
  group_by(game_id, player) %>% 
  filter(player == 1) %>%
  summarise(P1_Build_Df_building = n()) %>% 
  left_join(x_test, .) %>% 
  select(-player) -> x_test

test %>% 
  filter(event == "Ability" & str_detect(event_contents, "BuildSprineCrawler") | str_detect(event_contents, "BuildPlanetaryFortress") | 
           str_detect(event_contents, "BuildOrbitalCommand") | str_detect(event_contents, "BuildMissileTurret") | str_detect(event_contents, "BuildSensorTower") |str_detect(event_contents, "BuildBunker") |
           str_detect(event_contents, "BuildPhotonCannon")) %>% 
  group_by(game_id, player) %>% 
  filter(player == 0) %>%
  summarise(P0_Build_Df_building = n()) %>% 
  left_join(x_test, .) %>% 
  select(-player) -> x_test

x_test %>% 
  mutate(P1_Build_Df_building = str_replace_na(P1_Build_Df_building, 0),
         P1_Build_Df_building = as.numeric(P1_Build_Df_building),
         P0_Build_Df_building = str_replace_na(P0_Build_Df_building, 0),
         P0_Build_Df_building = as.numeric(P0_Build_Df_building)) -> x_test


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


## + [ Attack type ] ===================
## ++ [ target Attack ] ================
test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Attack") & str_detect(event_contents, "Target")) %>% 
  group_by(game_id, player) %>% 
  summarise(P1_Target_attack = n()) %>% 
  filter(player == 1) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Attack") & str_detect(event_contents, "Target")) %>% 
  group_by(game_id, player) %>% 
  summarise(P0_Target_attack = n()) %>% 
  filter(player == 0) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

x_test %>% 
  map_dfc(function(x) str_replace_na(x, 0)) %>% 
  map_dfc(function(x) as.numeric(x)) %>% 
  mutate(diff_Target_attac = P1_Target_attack - P0_Target_attack) %>% 
  select(-P1_Target_attack, -P0_Target_attack) -> x_test

## ++ [ non-target Attack ] ================
test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Attack") & !str_detect(event_contents, "Target")) %>% 
  group_by(game_id, player) %>% 
  summarise(P1_nonTarget_attack = n()) %>% 
  filter(player == 1) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

test %>% 
  filter(event == "Ability" & str_detect(event_contents, "Attack") & !str_detect(event_contents, "Target")) %>% 
  group_by(game_id, player) %>% 
  summarise(P0_nonTarget_attack = n()) %>% 
  filter(player == 0) %>% 
  left_join(x_test, ., by = "game_id") %>% 
  select(-player) -> x_test

x_test %>% 
  map_dfc(function(x) str_replace_na(x, 0)) %>% 
  map_dfc(function(x) as.numeric(x)) %>% 
  mutate(diff_nonTarget_attac = P1_nonTarget_attack - P0_nonTarget_attack) %>% 
  select(-P1_nonTarget_attack, -P0_nonTarget_attack) -> x_test

## + [ mult-building ] ================== 
base_buliding = c("Hatchery", "CommandCenter", "Nexus")
test %>% 
  filter(event == "Selection" & str_detect(event_contents, "BuildHatchery") | str_detect(event_contents, "BuildCommandCenter") | str_detect(event_contents, "BuildNexus") & player == 1) %>% 
  select(game_id, event_contents) %>% 
  unique() %>% 
  group_by(game_id) %>% 
  summarise(P1_mult_n = n()) %>% 
  mutate(P1_mult_n = str_replace_na(P1_mult_n, 1),
         P1_mult_n = as.numeric(P1_mult_n)) %>% 
  left_join(x_test, .) -> x_test

test %>% 
  filter(event == "Selection" & str_detect(event_contents, "BuildHatchery") | str_detect(event_contents, "BuildCommandCenter") | str_detect(event_contents, "BuildNexus") & player == 0) %>% 
  select(game_id, event_contents) %>% 
  unique() %>% 
  group_by(game_id) %>% 
  summarise(P0_mult_n = n()) %>% 
  mutate(P0_mult_n = str_replace_na(P0_mult_n, 1),
         P0_mult_n = as.numeric(P0_mult_n)) %>% 
  left_join(x_test, .) -> x_test

x_test %>% 
  mutate(P0_mult_n = str_replace_na(P0_mult_n, 0), 
         P0_mult_n = as.numeric(P0_mult_n),
         P1_mult_n = str_replace_na(P1_mult_n, 0),
         P1_mult_n = as.numeric(P1_mult_n)) -> x_test

## + [ command stop ] ====== 
test %>% 
  filter(player == 0, str_detect(event_contents, "Stop")) %>% 
  group_by(game_id) %>% 
  summarise(P0_command_stop = n()) %>% 
  left_join(x_test, .) %>% 
  mutate(P0_command_stop = str_replace_na(P0_command_stop, 0),
         P0_command_stop = as.numeric(P0_command_stop)) -> x_test

test %>% 
  filter(player == 1, str_detect(event_contents, "Stop")) %>% 
  group_by(game_id) %>% 
  summarise(P1_command_stop = n()) %>% 
  left_join(x_test, .) %>% 
  mutate(P1_command_stop = str_replace_na(P1_command_stop, 1),
         P1_command_stop = as.numeric(P1_command_stop)) -> x_test 

## + [ None-targe click ] ========================
test %>% 
  filter(player == 1 & event == "Right Click" & str_detect(event_contents, "Target: None")) %>% 
  group_by(game_id) %>% 
  summarise(P1_Nonetarget_click = n()) %>% 
  left_join(x_test, .) -> x_test

test %>% 
  filter(player == 0 & event == "Right Click" & str_detect(event_contents, "Target: None")) %>% 
  group_by(game_id) %>% 
  summarise(P0_Nonetarget_click = n()) %>% 
  left_join(x_test, .) -> x_test

x_test %>% 
  mutate(P1_Nonetarget_click = str_replace_na(P1_Nonetarget_click, 0),
         P0_Nonetarget_click = str_replace_na(P0_Nonetarget_click, 0),
         P1_Nonetarget_click = as.numeric(P1_Nonetarget_click),
         P0_Nonetarget_click = as.numeric(P0_Nonetarget_click)) -> x_test

## + [ dummy click ] =============================
test %>% 
  filter(player == 1 & event == "Right Click" & str_detect(event_contents, "Target")) %>% 
  filter(!str_detect(event_contents, "None")) %>% 
  group_by(game_id) %>% 
  summarise(P1_Click = n()) -> P1_dummyClick

test %>% 
  filter(player == 1 & event == "Right Click" & str_detect(event_contents, "Target")) %>% 
  filter(!str_detect(event_contents, "None")) %>% 
  unique() %>% 
  group_by(game_id) %>% 
  summarise(P1_UniqeClick = n()) %>% 
  left_join(P1_dummyClick, .) %>% 
  mutate(P1_dummyClick = P1_Click - P1_UniqeClick) %>% 
  select(game_id, P1_dummyClick) %>% 
  left_join(x_test, .) -> x_test

test %>% 
  filter(player == 0 & event == "Right Click" & str_detect(event_contents, "Target")) %>% 
  filter(!str_detect(event_contents, "None")) %>% 
  group_by(game_id) %>% 
  summarise(P0_Click = n()) -> P0_dummyClick

test %>% 
  filter(player == 0 & event == "Right Click" & str_detect(event_contents, "Target")) %>% 
  filter(!str_detect(event_contents, "None")) %>% 
  unique() %>% 
  group_by(game_id) %>% 
  summarise(P0_UniqeClick = n()) %>% 
  left_join(P0_dummyClick, .) %>% 
  mutate(P0_dummyClick = P0_Click - P0_UniqeClick) %>% 
  select(game_id, P0_dummyClick) %>% 
  left_join(x_test, .) -> x_test

x_test %>% 
  mutate(P1_dummyClick = str_replace_na(P1_dummyClick, 0),
         P1_dummyClick = as.numeric(P1_dummyClick),
         P0_dummyClick = str_replace_na(P0_dummyClick, 0),
         P0_dummyClick = as.numeric(P0_dummyClick)) -> x_test

## + [ EconomyBoosting ] ========================================
test %>%
  filter(player == 1 & str_detect(event_contents, "CalldownMULE") | str_detect(event_contents, "ChronoBoost") | str_detect(event_contents, "SpawnLarva")) %>% 
  group_by(game_id) %>% 
  summarise(P1_EconomyBoosting = n()) %>% 
  left_join(x_test, .) %>% 
  mutate(P1_EconomyBoosting = str_replace_na(P1_EconomyBoosting, 0),
         P1_EconomyBoosting = as.numeric(P1_EconomyBoosting)) -> x_test

test %>%
  filter(player == 0 & str_detect(event_contents, "CalldownMULE") | str_detect(event_contents, "ChronoBoost") | str_detect(event_contents, "SpawnLarva")) %>% 
  group_by(game_id) %>% 
  summarise(P0_EconomyBoosting = n()) %>% 
  left_join(x_test, .) %>% 
  mutate(P0_EconomyBoosting = str_replace_na(P0_EconomyBoosting, 0),
         P0_EconomyBoosting = as.numeric(P0_EconomyBoosting)) -> x_test

x_test %>% 
  map_dfc(function(x) sum(is.na(x))) %>% 
  gather(col_names, NA_prob, 1:length(.)) %>% 
  arrange(-NA_prob)

## ===========================================================================
x_test %>% 
  write.csv(., "tidy_test.csv", row.names = F)

