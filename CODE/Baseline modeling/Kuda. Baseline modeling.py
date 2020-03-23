# ============================================= [ setting ] ==========================================================
import pandas as pd  # 데이터 분석 라이브러리
import numpy as np  # 계산 라이브러리
from tqdm import tqdm  # 진행바
from sklearn.metrics import roc_auc_score  # AUC 스코어 계산
from sklearn.model_selection import KFold  # K-fold CV
from bayes_opt import BayesianOptimization  # 베이지안 최적화 라이브러리
from functools import partial  # 함수 변수 고정
import lightgbm as lgb  # LightGBM 라이브러리

tidy_train = pd.read_csv("/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./tidy_train.csv")

x_train = tidy_train.iloc[:, 1:38]
y_train = tidy_train.loc[:, "winner"]


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
            bagging_fraction=np.clip(bagging_fraction, 0, 1)
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


func_fixed = partial(lgb_cv, x_data=x_train, y_data=y_train, n_splits=5, output='score')

lgbBO = BayesianOptimization(
    func_fixed,
    {
        'num_leaves': (16, 1024),  # num_leaves,       범위(16~1024)
        'learning_rate': (0.0001, 0.1),  # learning_rate,    범위(0.0001~0.1)
        'n_estimators': (16, 1024),  # n_estimators,     범위(16~1024)
        'subsample': (0, 1),  # subsample,        범위(0~1)
        'colsample_bytree': (0, 1),  # colsample_bytree, 범위(0~1)
        'reg_alpha': (0, 10),  # reg_alpha,        범위(0~10)
        'reg_lambda': (0, 50),  # reg_lambda,       범위(0~50)
        "bagging_fraction": (0, 1)
    },
    random_state=21  # 시드 고정
)

lgbBO.maximize(init_points=5, n_iter=30)  # 처음 5회 랜덤 값으로 score 계산 후 50회 최적화

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
    x_data=x_train, y_data=y_train, n_splits=5, output='model')

tidy_test = pd.read_csv("/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./tidy_test.csv")
x_test = tidy_test.copy()

x_test = x_test.iloc[:, 1:]

preds = []
for model in models:
    pred = model.predict_proba(x_test)[:, 1]
    preds.append(pred)
pred = np.mean(preds, axis=0)

# ========================================================== [ output ] ===========================================================
submission = pd.read_csv(
    '/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./data/sample_submission.csv', index_col=0)
submission['winner'] = submission['winner'] + pred
submission.to_csv('/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./output3.csv')
submission.head()