## + [ Upgrade featuer ] =================
## ++ [ Attact Upgrade ] ================
attact_upgrade <- c("ShipWeapons", "InfantryWeapons", "GroundWeapons", "AirWeapons", "MeleeAttacks", 
                    "MissileAttacks", "FlyerAttacks")
train %>% 
  filter(player == 0 &str_detect(event_contents, attact_upgrade)) %>% 
  group_by(game_id,  player) %>% 
  summarise(attact_upgrade = n(),
            attact_upgrade = sum(attact_upgrade)) %>% 
  rename("P0_attact_upgrade" = attact_upgrade) %>% 
  select(-player) %>% 
  left_join(x_train, ., by = "game_id") -> x_train

train %>% 
  filter(player == 1 &str_detect(event_contents, attact_upgrade)) %>% 
  group_by(game_id,  player) %>% 
  summarise(attact_upgrade = n(),
            attact_upgrade = sum(attact_upgrade)) %>% 
  rename("P1_attact_upgrade" = attact_upgrade) %>% 
  select(-player) %>% 
  left_join(x_train, ., by = "game_id") -> x_train

## ++ [ defense Upgrade ] ================
defense_upgrad <- c("InfantryArmor", "VehicleandShipPlating", "GroundArmor", "Shields", "AirArmor", "GroundCarapace", "FlyerCarapace")

train %>% 
  filter(player == 0 &str_detect(event_contents, defense_upgrad)) %>% 
  group_by(game_id,  player) %>% 
  summarise(defense_upgrad = n(),
            defense_upgrad = sum(defense_upgrad)) %>% 
  rename("P0_defense_upgrad" = defense_upgrad) %>% 
  select(-player) %>% 
  left_join(x_train, ., by = "game_id") -> x_train

train %>% 
  filter(player == 1 &str_detect(event_contents, defense_upgrad)) %>% 
  group_by(game_id,  player) %>% 
  summarise(defense_upgrad = n(),
            defense_upgrad = sum(defense_upgrad)) %>% 
  rename("P1_defense_upgrad" = defense_upgrad) %>% 
  select(-player) %>% 
  left_join(x_train, ., by = "game_id") -> x_train

## ++ [ skiil Upgrade ] ================ 
skill <- c("PsionicStorm", "MetabolicBoost", "ExtendedThermalLance", "PathogenGlands",
           "AdrenalGlands", "Combat Shield", "Stimpack", "Concussive Shells", "Infernal Pre-Igniter",
           "Mag-FieldAccelerator", "DrillingClaws", "SmartServos", "CorvidReactor", "CloakingField",
           "HyperflightRotors", "EnhancedMunitions", "Mag-FieldLaunchers", "RecalibratedExplosives", "RapidFireLaunchers")

train %>% 
  filter(player == 0 & str_detect(event_contents, skill)) %>% 
  group_by(game_id,  player) %>% 
  summarise(skill = n(),
            skill = sum(skill)) %>% 
  rename("P0_skill_upgrad" = skill) %>% 
  select(-player) %>% 
  left_join(x_train, ., by = "game_id") -> x_train

train %>% 
  filter(player == 1 & str_detect(event_contents, skill)) %>% 
  group_by(game_id,  player) %>% 
  summarise(skill = n(),
            skill = sum(skill)) %>% 
  rename("P1_skill_upgrad" = skill) %>% 
  select(-player) %>% 
  left_join(x_train, ., by = "game_id") -> x_train

## ++ [ utile Upgrade ] ================ 
utile <- c("Charge", "Blink", "ResonatingGlaives", "ResonatingGlaives", "AnionPulse-Crystals", 
           "FluxVanes", "GravitonCatapult", "Burrow", "PneumatizedCarapace", "MutateVentralSacs")

train %>% 
  filter(player == 0 & str_detect(event_contents, utile)) %>% 
  group_by(game_id,  player) %>% 
  summarise(utile = n(),
            utile = sum(utile)) %>% 
  rename("P0_utile_upgrad" = utile) %>% 
  select(-player) %>% 
  left_join(x_train, ., by = "game_id") -> x_train

train %>% 
  filter(player == 1 & str_detect(event_contents, utile)) %>% 
  group_by(game_id,  player) %>% 
  summarise(utile = n(),
            utile = sum(utile)) %>% 
  rename("P1_utile_upgrad" = utile) %>% 
  select(-player) %>% 
  left_join(x_train, ., by = "game_id") -> x_train

