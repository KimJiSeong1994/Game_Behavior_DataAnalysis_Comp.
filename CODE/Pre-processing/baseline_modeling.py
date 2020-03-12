# ================================================== [ modeling ] ===================================================
import pandas as pd
import numpy as np
from tqdm import tqdm
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import KFold
from bayes_opt import BayesianOptimization  # 베이지안 최적화 라이브러리
from functools import partial               # 함수 변수 고정
import lightgbm as lgb                      # LightGBM 라이브러리

def lgb_cv(num_leaves, learning_rate, n_estimators, subsample, colsample_bytree, reg_alpha, reg_lambda, x_data=None,
           y_data=None, n_splits=5, output='score'):
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

func_fixed = partial(lgb_cv, x_data = x_train, y_data = y_train, n_splits=5, output='score')
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
    },
    random_state=4321
)
lgbBO.maximize(init_points=5, n_iter=30)

# ================================================== [ model tuning ] ==================================================
params = lgbBO.max['params']
models = lgb_cv(
    params['num_leaves'],
    params['learning_rate'],
    params['n_estimators'],
    params['subsample'],
    params['colsample_bytree'],
    params['reg_alpha'],
    params['reg_lambda'],
    x_data=x_train, y_data=y_train, n_splits=5, output='model')