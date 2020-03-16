# =========================================================== [ setting ] ==========================================================
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
import os

os.chdir("C:/Users/knuser/Desktop/data")
train = pd.read_csv('train.csv')

df_train = pd.DataFrame(train.game_id.unique(), columns=['game_id'])
df_train.index = df_train.game_id
df_train = df_train.drop(['game_id'], axis = 1)

## + [ 처음 기록 된 카메라 좌표를 기록 ] =====================
df_train_p0 = train[(train.event=='Camera')&(train.player==0)]
df_train_p0 = df_train_p0[df_train_p0.shift(1).game_id!=df_train_p0.game_id] # 쉬프트를 이용하여 각 게임의 첫번째 데이터 찾기
df_train_p0 = df_train_p0.iloc[:, [0,6]].rename({'event_contents':'player0_starting'}, axis = 1)
df_train_p0.index = df_train_p0['game_id']
df_train_p0 = df_train_p0.drop(['game_id'], axis=1)
df_train = pd.merge(df_train, df_train_p0, on='game_id', how='left')
del df_train_p0

df_train_p1 = train[(train.event=='Camera')&(train.player==1)]
df_train_p1 = df_train_p1[df_train_p1.shift(1).game_id!=df_train_p1.game_id]
df_train_p1 = df_train_p1.iloc[:, [0,6]].rename({'event_contents':'player1_starting'}, axis = 1)
df_train_p1.index = df_train_p1['game_id']
df_train_p1 = df_train_p1.drop(['game_id'], axis=1)
df_train = pd.merge(df_train, df_train_p1, on='game_id', how='left')
del df_train_p1

## + [ x, y 값으로 분리 ] ==================================
df_train['player0_starting'] = df_train.player0_starting.str.split('(').str[1]
df_train['player0_starting'] = df_train.player0_starting.str.split(')').str[0]
split_xy = df_train.player0_starting.str.split(',')
df_train['player0_x'] = split_xy.str[0].astype('float')
df_train['player0_y'] = split_xy.str[1].astype('float')
del split_xy

df_train['player1_starting'] = df_train.player1_starting.str.split('(').str[1]
df_train['player1_starting'] = df_train.player1_starting.str.split(')').str[0]
split_xy = df_train.player1_starting.str.split(',')
df_train['player1_x'] = split_xy.str[0].astype('float')
df_train['player1_y'] = split_xy.str[1].astype('float')
del split_xy

## [ 플레이어의 x,y 좌표를 하나로 모음 ] =======================
location_p0 = df_train.loc[:, ['player0_x', 'player0_y']]
location_p0 = location_p0.rename({'player0_x':'location_x', 'player0_y':'location_y'}, axis=1)

location_p1 = df_train.loc[:, ['player1_x', 'player1_y']]
location_p1 = location_p1.rename({'player1_x':'location_x', 'player1_y':'location_y'}, axis=1)
location_p1.index += location_p0.index[-1]+1

location = pd.concat([location_p0, location_p1])
location = location.dropna()
del location_p0, location_p1

df_train.player0_starting.value_counts().head(20) # 스타팅 컬럼을 카운팅을 해보면 15개의 포이트가 많음, 15개의 스타팅포인트 존재

## + [ kmeans를 이용하여 15개로 클러스터링 ] =================
kmeans_clst = KMeans(n_clusters=15).fit(location)
location['starting'] = kmeans_clst.labels_+1

for cluster in range(15): # kmeans로 찾은 15개의 포인트에서 각 데이터들의 거리 계산
    point = location[location.starting==cluster+1]
    loc = point.loc[:,['location_x', 'location_y']]
    del point
    loc['center_x'] = kmeans_clst.cluster_centers_[cluster][0]
    loc['center_y'] = kmeans_clst.cluster_centers_[cluster][1]
    distance = np.sqrt(np. square(loc.location_x - loc.center_x) + np.square(loc.location_y - loc.center_y))
    location.loc[loc.index, 'distance'] = distance
    del loc

## [ 일정 거리(5)이상 떨어진 데이터는 starting을 0으로 지정 ] ==============
idx = location[location.distance > 5].index
location.loc[idx, 'starting'] = 0
del idx

df_train = df_train.reset_index()
location = location.reset_index()

df_train['player0_starting'] = location.loc[df_train.index, 'starting'] # 클러스터링한 결과 반영
location.index -= (df_train.index[-1]+1)
df_train['player1_starting'] = location.loc[df_train.index, 'starting']
del location

df_train = df_train.drop(['player0_x', 'player0_y', 'player1_x', 'player1_y'], axis = 1) # 불필요한 컬럼 삭제
df_train = df_train.fillna(0)

## + [ 스타팅 포인트를 이용하여 맵 분류 ] ==================================
map_list = []
for point in range(1,16):
    couple = df_train[df_train.player0_starting == point].player1_starting.value_counts()
    if couple[couple.index[1]]<100:
        map_list.append([point, couple.index[0], 999])
    else:
        map_list.append([point, couple.index[0], couple.index[1]])
map_list = np.sort(map_list, axis = 1)
map_list = np.unique(map_list, axis = 0)

len(df_train[(df_train.player0_starting == 0)|(df_train.player1_starting == 0)]) # 스타팅을 모르는 게임 수 확인.

## + [ map_list와 상대편 위치 정보를 이용하여 모르는 스타팅 찾기 ] ==========
for m in map_list:
    idx = df_train[(df_train.player0_starting == 0) & (
                (df_train.player1_starting == m[0]) | (df_train.player1_starting == m[2]))].index
    df_train.loc[idx, 'player0_starting'] = m[1]
    del idx
    idx = df_train[(df_train.player0_starting == 0) & (
                (df_train.player1_starting == m[1]) | (df_train.player1_starting == m[2]))].index
    df_train.loc[idx, 'player0_starting'] = m[0]
    del idx

    idx = df_train[(df_train.player1_starting == 0) & (
                (df_train.player0_starting == m[0]) | (df_train.player0_starting == m[2]))].index
    df_train.loc[idx, 'player1_starting'] = m[1]
    del idx
    idx = df_train[(df_train.player1_starting == 0) & (
                (df_train.player0_starting == m[1]) | (df_train.player0_starting == m[2]))].index
    df_train.loc[idx, 'player1_starting'] = m[0]
    del idx

df_train[(df_train.player0_starting == 0)|(df_train.player1_starting == 0)].head() # 모든 게임의 스타팅포인트를 찾음

## + [ 맵 컬럼 추가 ] ==========================================================
for map_num, m in enumerate(map_list):
    idx = df_train[(df_train.player0_starting == m[0])|(df_train.player0_starting == m[1])|(df_train.player0_starting == m[2])].index
    df_train.loc[idx, 'map'] = map_num
del idx, map_list

df_train.head()