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


train = pd.read_csv('C:/Users/HSystem/Desktop/data/train.csv')
x_train, y_train = data_preparation(train, answer=True)
x_train.head()


# ========================================================== [ modeling ] ===========================================================
## + [lightGBM modeling ] ==================================
def lgb_cv(num_leaves, learning_rate, n_estimators, subsample, colsample_bytree, reg_alpha, reg_lambda,
           bagging_fraction, x_data=None, y_data=None, n_splits=5, output='score'):
    score = 0
    kf = KFold(n_splits=n_splits)
    models = []
    for train_index, valid_index in kf.split(x_data):
        x_train, y_train = x_data.iloc[train_index], y_data[train_index]
        x_valid, y_valid = x_data.iloc[valid_index], y_data[valid_index]

        model = lgb.LGBMClassifier(
            num_leaves=int(num_leaves),
            learning_rate=learning_rate,
            n_estimators=int(n_estimators),
            subsample=np.clip(subsample, 0, 1),
            colsample_bytree=np.clip(colsample_bytree, 0, 1),
            reg_alpha=reg_alpha,
            reg_lambda=reg_lambda,
            bagging_fraction=np.clip(bagging_fraction, 0, 1),
            feature_fraction=np.clip(feature_fraction, 0.5, 1)
        )

        model.fit(x_train, y_train)
        models.append(model)

        pred = model.predict_proba(x_valid)[:, 1]
        true = y_valid
        score += roc_auc_score(true, pred) / n_splits

    if output == 'score':
        return score
    if output == 'model':
        return models


func_fixed = partial(lgb_cv,
                     x_data=x_train,
                     y_data=y_train,
                     n_splits=5,
                     output='score')

lgbBO = BayesianOptimization(
    func_fixed,
    {
        'num_leaves': (16, 1024),
        'learning_rate': (0.0001, 0.1),
        'n_estimators': (16, 1024),
        'subsample': (0, 1),
        'colsample_bytree': (0, 1),
        'reg_alpha': (0, 10),
        'reg_lambda': (0, 50),
        "bagging_fraction": (0, 1)
    },
    random_state = 21
)

lgbBO.maximize(init_points = 5, n_iter = 30) # n_iter = 30 steps

params = lgbBO.max['params']
models = lgb_cv(
    params['num_leaves'],
    params['learning_rate'],
    params['n_estimators'],
    params['subsample'],
    params['colsample_bytree'],
    params['reg_alpha'],
    params['reg_lambda'],
    params["bagging_fraction"],
    x_data = x_train, y_data = y_train, n_splits = 5, output = 'model')

test = pd.read_csv('C:/Users/HSystem/Desktop/data/test.csv')
x_test, _ = data_preparation(test, answer=False)

preds = []
for model in models:
    pred = model.predict_proba(x_test)[:, 1]
    preds.append(pred)
pred = np.mean(preds, axis=0)

# ========================================================== [ output ] ===========================================================
submission = pd.read_csv('C:/Users/HSystem/Desktop/data/sample_submission.csv', index_col=0)
submission['winner'] = submission['winner'] + pred
submission.to_csv('C:/Users/HSystem/Desktop/data/submission.csv')
submission.head()



# ======================================= [ Deeplearning model ] ========================================
from keras import models
from keras import layers

model = models.Sequential()
model.add(layers.Dense(64, input_dim = 26, activation = "relu"))
model.add(layers.Dense(64, activation = "relu"))
model.add(layers.Dense(1, activation = "sigmoid"))
model.compile(optimizer  = "adam",
             loss  = "binary_crossentropy",
             metrics = ["accuracy"])

history = model.fit(x_train, y_train,
                   epochs = 100,
                   batch_size = 32,
                   validation_split = 0.2)

print('\nAccuracy: {:.4f}'.format(model.evaluate(x_train, y_train)[1]))

