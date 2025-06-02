#Paquetes
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
from pptx import Presentation
from pptx.util import Inches, Pt
from scipy.stats import f_oneway
from math import pi

# BD
df = pd.read_excel("Segmentacion_CATT.xlsx")
df = df[df["trafico_clientes"] != 0].copy()

# Ruta de resultados
OUTPUT_DIR = "resultados_seg"
os.makedirs(OUTPUT_DIR, exist_ok=True)

NUM_VARS = [
    "capturas_tarjetas", "aprobacion_tarjetas", "tarjetas",
    "capturas_creditos", "aprobacion_creditos", "cantidad_creditos",
    "monto_creditos", "seguros", "trafico_transaccional",
    "trafico_clientes", "aprovechamiento_de_trafico", "contribucion"
]

# Limpieza BD
df[NUM_VARS] = df[NUM_VARS].fillna(df[NUM_VARS].median())
X_scaled = StandardScaler().fit_transform(df[NUM_VARS])

# Clusters
sil_scores = {}
for k in range(2, 7):
    km = KMeans(n_clusters=k, random_state=42, n_init=10)
    sil_scores[k] = silhouette_score(X_scaled, km.fit_predict(X_scaled))

k_final = 3
df["cluster"] = KMeans(n_clusters=k_final, random_state=42, n_init=10)\
                    .fit_predict(X_scaled)

cluster_counts = df["cluster"].value_counts().sort_index()
cluster_means  = df.groupby("cluster")[NUM_VARS].mean()

# ANOVA
anova_df = (
    pd.DataFrame({
        "Variable": NUM_VARS,
        "p_value": [
            f_oneway(*[df[df["cluster"] == c][v] for c in range(k_final)])[1]
            for v in NUM_VARS
        ]
    })
    .assign(Sig=lambda d: np.where(d["p_value"] < 0.05, "✔", ""))
    .sort_values("p_value")
)

# Graficos
def save_fig(name):
    path = os.path.join(OUTPUT_DIR, name)
    plt.savefig(path, bbox_inches="tight")
    plt.close()
    return path

# 1. Silhouette
plt.figure()
plt.plot(list(sil_scores.keys()), list(sil_scores.values()), marker="o")
plt.xlabel("k"); plt.ylabel("Silhouette"); plt.title("Silhouette vs. k")
sil_plot = save_fig("silhouette_plot.png")

# 2. Conteo de clústeres
plt.figure()
plt.bar(cluster_counts.index.astype(str), cluster_counts.values)
plt.xlabel("Clúster"); plt.ylabel("N° puntos"); plt.title("Tamaño de clústeres")
count_plot = save_fig("cluster_count_plot.png")

# 3. Contribución
plt.figure()
plt.bar(cluster_means.index.astype(str), cluster_means["contribucion"])
plt.xlabel("Clúster"); plt.ylabel("Contribución"); plt.title("Contribución promedio")
contrib_plot = save_fig("contrib_plot.png")

# 4. Radar
plt.figure(figsize=(8, 8))
norm_means = (cluster_means - cluster_means.min()) / (cluster_means.max() - cluster_means.min())
angles = [n / float(len(NUM_VARS)) * 2 * pi for n in range(len(NUM_VARS))] + [0]
for c in range(k_final):
    vals = norm_means.loc[c].tolist() + [norm_means.loc[c].tolist()[0]]
    plt.polar(angles, vals, label=f"Clúster {c}")
plt.xticks(angles[:-1], NUM_VARS, size=7); plt.title("Radar de medias normalizadas")
plt.legend(loc='upper right', bbox_to_anchor=(1.3, 1.1))
radar_plot = save_fig("radar_plot.png")
