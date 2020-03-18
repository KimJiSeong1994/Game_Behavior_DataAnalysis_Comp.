# ============================================= [ setting ] ==========================================================
import pandas as pd  # 데이터 분석 라이브러리
import numpy as np  # 계산 라이브러리
from tqdm import tqdm  # 진행바
from sklearn.metrics import roc_auc_score  # AUC 스코어 계산
from sklearn.model_selection import KFold  # K-fold CV
from bayes_opt import BayesianOptimization  # 베이지안 최적화 라이브러리
from functools import partial  # 함수 변수 고정
import lightgbm as lgb  # LightGBM 라이브러리

# ============================================= [ pre-processing ] ==============================================

def species_converter(string):
    if string == 'T':
        return 0
    elif string == 'P':
        return 1
    elif string == 'Z':
        return 2
    else:
        raise ValueError


def data_preparation(df, answer=False):
    game_ids = df['game_id'].unique()
    events = ['Ability', 'AddToControlGroup', 'Camera', 'ControlGroup', 'GetControlGroup', 'Right Click', 'Selection',
              'SetControlGroup']
    unique_event_0, unique_event_1, delta_event = {}, {}, {}
    for event in events:
        unique_event_0['P0_' + event] = 0
        unique_event_1['P1_' + event] = 0
        delta_event['delta_' + event] = 0

    species = df.groupby(['game_id', 'player']).species.unique()
    event_count = df.groupby(['game_id', 'player']).event.value_counts()
    if answer:
        winners = df.groupby(['game_id']).winner.max()

    x_data, y_data = [], []
    for game_id in tqdm(game_ids):
        df_event_count = event_count[game_id].unstack(level=-1)
        df = pd.DataFrame(species[game_id])
        df = pd.concat([df, df_event_count], axis=1)
        df = df.fillna(0)

        df_P0_species = pd.DataFrame([species_converter(df.loc[0]['species'][0])], columns=['P0_species'])
        df_P1_species = pd.DataFrame([species_converter(df.loc[1]['species'][0])], columns=['P1_species'])
        df = df.drop(['species'], axis=1)

        df_P0_event = unique_event_0.copy()
        for column in df.columns:
            df_P0_event['P0_' + column] = df.loc[0][column]
        df_P0_event = pd.DataFrame(pd.Series(df_P0_event)).T

        df_P1_event = unique_event_1.copy()
        for column in df.columns:
            df_P1_event['P1_' + column] = df.loc[1][column]
        df_P1_event = pd.DataFrame(pd.Series(df_P1_event)).T

        df_delta_event = delta_event.copy()
        for column in df.columns:
            df_delta_event['delta_' + column] = df_P0_event['P0_' + column][0] - df_P1_event['P1_' + column][0]
        df_delta_event = pd.DataFrame(pd.Series(df_delta_event)).T

        out = pd.concat([df_P0_species, df_P0_event, df_P1_species, df_P1_event, df_delta_event], axis=1)
        out.index = [game_id]
        out.index.name = 'game_id'

        x_data.append(out)
        if answer:
            y_data.append(winners[game_id])

    x_data = pd.concat(x_data)
    y_data = np.array(y_data)

    return x_data, y_data


train = pd.read_csv('/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./data/train.csv')
x_train, y_train = data_preparation(train, answer=True)
x_train.head()

## + [ featuer importance ] ==============
import matplotlib.pyplot as plt
import seaborn as sns
from xgboost import XGBClassifier, plot_importance
% matplotlib
inline

model = XGBClassifier()
model.fit(x_train, y_train)

sorted_idx = np.argsort(model.feature_importances_)[::-1]
for index in sorted_idx:
    print([x_train.columns[index], model.feature_importances_[index]])

plot_importance(model)
plt.show()

# 종족전을 명목변수화
x_train["Battle_species"] = "unknown"
x_train.loc[(x_train["P0_species"] == 0) & (x_train["P1_species"] == 0), "Battle_species"] = 1
x_train.loc[(x_train["P0_species"] == 0) & (x_train["P1_species"] == 1), "Battle_species"] = 2
x_train.loc[(x_train["P0_species"] == 0) & (x_train["P1_species"] == 2), "Battle_species"] = 3
x_train.loc[(x_train["P0_species"] == 1) & (x_train["P1_species"] == 0), "Battle_species"] = 4
x_train.loc[(x_train["P0_species"] == 1) & (x_train["P1_species"] == 1), "Battle_species"] = 5
x_train.loc[(x_train["P0_species"] == 1) & (x_train["P1_species"] == 2), "Battle_species"] = 6
x_train.loc[(x_train["P0_species"] == 2) & (x_train["P1_species"] == 0), "Battle_species"] = 7
x_train.loc[(x_train["P0_species"] == 2) & (x_train["P1_species"] == 1), "Battle_species"] = 8
x_train.loc[(x_train["P0_species"] == 2) & (x_train["P1_species"] == 2), "Battle_species"] = 9

del x_train["P0_species"], x_train["P1_species"]

corr_df = x_train.corr()

fig, ax = plt.subplots(figsize = (12, 12))
mask = np.zeros_like(corr_df, dtype = np.bool)
mask[np.triu_indices_from(mask)] = True

sns.heatmap(corr_df,
            cmap = "RdYlBu_r",
            annot = True,
            mask = mask,
            linewidths = 0.5,
            cbar_kws = {"shrink" : 0.5},
            vmin = -1, vmax = 1)
plt.show()
