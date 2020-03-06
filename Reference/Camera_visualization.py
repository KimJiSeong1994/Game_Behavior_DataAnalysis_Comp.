# ================================================== [ setting ] ====================================================
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


def plot_camera(df, game_id):
    df = df.loc[df['game_id'] == game_id]
    df = df.loc[df['event'] == 'Camera']
    df_0 = df.loc[df['player'] == 0]
    df_1 = df.loc[df['player'] == 1]

    winner = df['winner'].iloc[0]
    game_time = df['time'].values[-1]
    player_0_species = df_0['species'].iloc[0]
    player_1_species = df_1['species'].iloc[0]

    player_0_camera = np.array(
        [item.replace('at (', '').replace(')', '').split(',') for item in df_0['event_contents']]).astype(float)
    player_1_camera = np.array(
        [item.replace('at (', '').replace(')', '').split(',') for item in df_1['event_contents']]).astype(float)

    plt.scatter(player_0_camera[:, 0], player_0_camera[:, 1], label='player_0', alpha=0.3, color='b', s=50)
    plt.scatter(player_1_camera[:, 0], player_1_camera[:, 1], label='player_1', alpha=0.3, color='r', s=50)
    plt.legend()
    plt.show()

    print('Total game time: %s' % (game_time))
    print('Winner: Player_%i' % (winner))
    print('Player_0: %s' % (player_0_species))
    print('Player_1: %s' % (player_1_species))

train = pd.read_csv('data/train.csv')

# =============================================== [ visualization ] ===============================================
plot_camera(train, 0)
plot_camera(train, 100)
plot_camera(train, 2000)
plot_camera(train, 30000)