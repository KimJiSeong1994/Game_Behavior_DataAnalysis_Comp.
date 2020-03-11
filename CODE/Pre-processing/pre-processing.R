# ============================================ [ setting ] =========================================
library(data.table); library(tidyverse); library(dummies)
train = fread("/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./data/train.csv", sep = ",", head = T, stringsAsFactors = T, encoding = "UTF-8")
train <- train[1:30000000, ]

## + [ pre-processing ] ======================
train %>%
  dummy.data.frame(names = "event", sep = "_") -> train  # one-hot encoding 
names(train) <- str_remove_all(names(train), "\\s")   # remove `\\s` string 
train$game_id <- train$game_id + 1 # game_id num obs : 1 이 시작으로 수정 

train %>%
  mutate(species = case_when(species == "T" ~ 1,
                             species == "P" ~ 2,
                             species == "Z" ~ 3),
         species = as.factor(species)) %>% 
  group_split(game_id) %>%
  map(function(x) x %>%
        group_by(player) %>%
        summarise(game_id = unique(game_id),
                  winner = unique(winner),
                  time = max(time),
                  species = unique(species),
                  event_Ability = sum(event_Ability),
                  event_AddToControlGroup = sum(event_AddToControlGroup),
                  event_Camera = sum(event_Camera),
                  event_ControlGroup = sum(event_ControlGroup),
                  event_GetControlGroup = sum(event_GetControlGroup),
                  event_RightClick = sum(event_RightClick),
                  event_Selection = sum(event_Selection),
                  event_SetControlGroup = sum(event_SetControlGroup))) -> tidy # data grouping 

game_id <- unique(train$game_id)
tidy_data = data.frame(NULL)
for(i in unique(train$game_id)) {
  tidy[[i]] %>% 
    mutate(game_id = i,
           win_lose = ifelse(player == winner, 1, 0)) %>%
    select(-c(winner, player)) %>% 
    rbind(tidy_data, .) -> train 
}

# ============================================ [ modeling ] =========================================

