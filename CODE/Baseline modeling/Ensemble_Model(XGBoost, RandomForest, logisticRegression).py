# ============================================ [ modeling ] =======================================================
## + [ XGBoost model ] ======================
from xgboost import plot_importance
from xgboost import XGBClassifier

x_train = df_train.iloc[:, 1:30]
y_train = df_train["winner"]

xgb = XGBClassifier(n_leaves = 128,
                    learning_rate = 0.01,
                    n_estimators = 512,
                    subsample = 0.6,
                    colsample_bytree = 0.5,
                    reg_alpha = 2,
                    reg_lambda = 2,
                    max_depth = 4,
                    random_state = 21)

xgb.fit(x_train, y_train)

## + [ Randomforest ] ==========================
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

rf_model = RandomForestClassifier(n_estimators = 100,
                                 oob_score = True,
                                 random_state = 21)
rf_model.fit(x_train, y_train)

## + [ logistic regression model ] ==========================
from sklearn.linear_model import LogisticRegression

logit_model = LogisticRegression(random_state = 0)
logit_model.fit(x_train, y_train)

# ============================================ [ model ensemble ] ==================================================
from sklearn.ensemble import VotingClassifier
from sklearn.model_selection import cross_validate
k_fold = 5

models = [("XGBoost", xgb),
          ("RandomForest", rf_model),
          ("LogisticRegression", logit_model)]

soft_vote = VotingClassifier(models, voting = "soft")
soft_vote_cv = cross_val_score(soft_vote, x_train, y_train, cv = k_fold)
soft_vote.fit(x_train, y_train)

ensemble_pred = soft_vote.predict_proba(x_test)
ensemble_pred = pd.DataFrame({"winner" : ensemble_pred[:, 0]})
print(ensemble_pred)

# ============================================ [ Make submission file ] ==================================================
submission = pd.read_csv("/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./data/submission.csv", index_col = 0)
submission = submission.reset_index()
submission["winner"] = ensemble_pred["winner"]
submission = submission.set_index(["game_id"])
submission.to_csv("/Users/gimjiseong/Downloads/[ DACON ] Game_Behavior_DataAnalysis_Comp./data/output_ensembleModel.csv")
