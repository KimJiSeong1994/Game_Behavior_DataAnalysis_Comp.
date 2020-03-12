# ============================================ [ setting ] =======================================================
import numpy as np
import pandas as pd

train = pd.read_csv("/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./data/train.csv")
test = pd.read_csv("/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./data/train.csv")

## + [ pre-processing ] ======================
df_train = pd.DataFrame(columns = ['game_id']) # game id
df_train.game_id = train.game_id.unique()

df_train['time'] = np.array(train[train.shift(-1).game_id != train.game_id].time) # game time

df = train[train.player == 0]
df_train['player0_species'] = np.array(df[df.shift(-1).game_id != df.game_id].species)
df = train[train.player==1]
df_train['player1_species'] = np.array(df[df.shift(-1).game_id != df.game_id].species)

df = train[train.player == 0]
df_train['event_count_0'] = np.array(df.game_id.value_counts()[df.game_id.unique()])
df = train[train.player == 1]
df_train['event_count_1'] = np.array(df.game_id.value_counts()[df.game_id.unique()])

for event in train.event.unique():
    df = train[(train.player == 0)&(train.event == event)]
    df = pd.DataFrame(df.game_id.value_counts()[df.game_id.unique()]).rename({'game_id':event+'_count_0'}, axis = 1)
    df['game_id']= np.array(df.index)
    df_train = pd.merge(df_train, df, on='game_id', how='left')

    df = train[(train.player == 1)&(train.event == event)]
    df = pd.DataFrame(df.game_id.value_counts()[df.game_id.unique()]).rename({'game_id':event+'_count_1'}, axis = 1)
    df['game_id']= np.array(df.index)
    df_train = pd.merge(df_train, df, on = 'game_id', how = 'left')
df_train = df_train.fillna(0)

for event in train.event.unique():
    df_train[event + '_diff'] = df_train[event+'_count_0'] - df_train[event+'_count_1']

df_train['winner'] = np.array(train[train.shift(-1).game_id != train.game_id].winner)

idx = df_train[df_train.player0_species=='T'].index
df_train.loc[idx, 'player0_species'] = 0
idx = df_train[df_train.player0_species=='P'].index
df_train.loc[idx, 'player0_species'] = 1
idx = df_train[df_train.player0_species=='Z'].index
df_train.loc[idx, 'player0_species'] = 2

idx = df_train[df_train.player1_species=='T'].index
df_train.loc[idx, 'player1_species'] = 0
idx = df_train[df_train.player1_species=='P'].index
df_train.loc[idx, 'player1_species'] = 1
idx = df_train[df_train.player1_species=='Z'].index
df_train.loc[idx, 'player1_species'] = 2

df_test = pd.DataFrame(columns = ['game_id']) # game id
df_test.game_id = test.game_id.unique()

df_test['time'] = np.array(test[test.shift(-1).game_id != test.game_id].time) # game time

df = test[test.player == 0]
df_test['player0_species'] = np.array(df[df.shift(-1).game_id != df.game_id].species)
df = test[test.player==1]
df_test['player1_species'] = np.array(df[df.shift(-1).game_id != df.game_id].species)

df = test[test.player == 0]
df_test['event_count_0'] = np.array(df.game_id.value_counts()[df.game_id.unique()])
df = test[test.player == 1]
df_test['event_count_1'] = np.array(df.game_id.value_counts()[df.game_id.unique()])

for event in test.event.unique():
    df = test[(test.player == 0)&(test.event == event)]
    df = pd.DataFrame(df.game_id.value_counts()[df.game_id.unique()]).rename({'game_id':event+'_count_0'}, axis = 1)
    df['game_id']= np.array(df.index)
    df_test = pd.merge(df_test, df, on='game_id', how='left')

    df = test[(test.player == 1)&(test.event == event)]
    df = pd.DataFrame(df.game_id.value_counts()[df.game_id.unique()]).rename({'game_id':event+'_count_1'}, axis = 1)
    df['game_id']= np.array(df.index)
    df_test = pd.merge(df_test, df, on = 'game_id', how = 'left')
df_test = df_test.fillna(0)

for event in train.event.unique():
    df_test[event + '_diff'] = df_test[event+'_count_0'] - df_test[event+'_count_1']

idx = df_test[df_test.player0_species=='T'].index
df_test.loc[idx, 'player0_species'] = 0
idx = df_test[df_test.player0_species=='P'].index
df_test.loc[idx, 'player0_species'] = 1
idx = df_test[df_test.player0_species=='Z'].index
df_test.loc[idx, 'player0_species'] = 2

idx = df_test[df_test.player1_species=='T'].index
df_test.loc[idx, 'player1_species'] = 0
idx = df_test[df_test.player1_species=='P'].index
df_test.loc[idx, 'player1_species'] = 1
idx = df_test[df_test.player1_species=='Z'].index
df_test.loc[idx, 'player1_species'] = 2

x_test = df_test.iloc[:, 1:30]

## + [ train, validation dataset split ] =========
from sklearn.model_selection import train_test_split
train_x, val_x, train_y, val_y = train_test_split(x_train, y_train, stratify = y_train, test_size = 0.2, random_state = 42)
