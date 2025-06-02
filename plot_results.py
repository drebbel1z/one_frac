#!/usr/bin/env python3

import pandas as pd
import os
import sys
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import math
import re

# -------------------------------------------------------------------------------

# low perm matrix
# df = pd.read_csv("outputs/results.csv")
df = pd.read_csv("outputs/results_nlmat_20m_orig.csv")

df_30day_exp_mass = pd.read_csv(
    "/Users/otchc/projects/FORGE_THM/th_dfn_circulation/field_data//16B_30day_experimental_output.csv"
)
df_30day_exp_press = pd.read_csv(
    "/Users/otchc/projects/FORGE_THM/th_dfn_circulation/field_data//field_circulation_data_August_2024_raw.csv"
)
df_58_32 = pd.read_csv(
    "/Users/otchc/projects/FORGE_THM/th_dfn_circulation/field_data//58-32_30day_08_2024.csv"
)

print(
    "\n\n16B_30day_experimental_output.csv description: ",
    list(df_30day_exp_mass.columns),
)
print(
    "\n\nfield_circulation_data_August_2024_raw.csv description: ",
    list(df_30day_exp_press.columns),
)
print(
    "\n\n58-32_30day_08_2024.csv description: ",
    list(df_58_32.columns),
)


#
# FIXME LYNN ALIGN ALL OF THESE PLOTS WITH DATE AND TIME.
#
# format Pengju's pressure data time to get elapsed time and offset
df_30day_exp_press["datetime"] = pd.to_datetime(
    df_30day_exp_press["YYYY/MM/DD"] + " " + df_30day_exp_press["HH:MM:SS"]
)
df_30day_exp_press["time_elapsed"] = (
    df_30day_exp_press["datetime"] - df_30day_exp_press["datetime"].iloc[0]
)
df_30day_exp_press["time_elapsed"] = df_30day_exp_press[
    "time_elapsed"
].dt.total_seconds()
# offsetting to pump start time
df_30day_exp_press["time_elapsed"] = df_30day_exp_press["time_elapsed"] - 5.84e5

#
# format Robs 58-32 data
df_58_32["date/time"] = pd.to_datetime(df_58_32["date/time"], format="%m/%d/%y %H:%M")
start_datetime = pd.to_datetime("2024-08-08 09:28:00")
end_datetime = pd.to_datetime("2024-09-08 09:28:00")
df_58_32 = df_58_32[
    (df_58_32["date/time"] >= start_datetime) & (df_58_32["date/time"] <= end_datetime)
]
# compute offset time based on the data in pump file (field_circulation_data_August_2024_raw.csv)
start_time = df_30day_exp_press["datetime"].iloc[0]
df_58_32["time_elapsed"] = (df_58_32["date/time"] - start_time).dt.total_seconds()
# offsetting to pump start time
df_58_32["time_elapsed"] = df_58_32["time_elapsed"] - 7.6e5
df_58_32["pressure (psi)"] = df_58_32["pressure (psi)"].astype(float)
print(df_58_32.info)
#
# Offset time of df_30day_exp_mass mass output to align with simulations
# 114500s is when main injection starts.  Removing the first heaviside injection
df_30day_exp_mass["time"] = df_30day_exp_mass["time"] + 70090


print("\n\ncsv dataframe description: ", df.columns.values)
gpm_to_bpm = 0.0317460317
kgs_to_bpm = 1 / 2.65
CtoK = 273.15
cp = 4187  # j/kg*C
MPa_to_psi = 145.038
time_max_limit = df.loc[:, "time"].max() / 3600 / 24


# --------------------------------------------------------------------
#  PLOTTING FIGURES
#
#
# Temperature from peaceman enthalpy
def fahrenheit_to_kelvin(fahrenheit):
    kelvin = (fahrenheit - 32) * 5.0 / 9.0 + CtoK
    return kelvin


plt.figure(figsize=(10, 6))
plt.plot(
    df_30day_exp_press["time_elapsed"] / 3600 / 24,
    df_30day_exp_press["16B-DIS TEMP (DEGREES F)"].apply(fahrenheit_to_kelvin),
    linestyle="-",
    linewidth=2,
    color="grey",
    label="Field Production",
)
plt.plot(
    df["time"] / 3600 / 24,
    df["energy_prod"] / df["fluid_report"] / cp + CtoK,
    "-r",
)
plt.ylabel("Energy Temperature (K)")
plt.xlabel("Time (days)")
plt.title("Temperature Peaceman UserObject Temperature")
plt.grid()

#
#
# Mass production from peaceman
fig, ax1 = plt.subplots(1, 1, figsize=(10, 6))
ax1.plot(
    df["time"] / 3600 / 24,
    df["fluid_report"] / df["a1_dt"] * kgs_to_bpm,
    "-r",
    label="Simulation Production",
)
ax1.plot(
    df["time"] / 3600 / 24,
    df["injection_rate_kg_s"] * kgs_to_bpm,
    "-b",
    label="Field Injection",
)
ax1.plot(
    df_30day_exp_mass["time"] / 3600 / 24 - 0.8,
    df_30day_exp_mass["m_out_kg_s"] * kgs_to_bpm,
    linestyle="--",
    linewidth=2,
    color="black",
    label="Field Production",
)
ax1.legend()
ax1.set_ylabel("Mass Rate (bpm)")
ax1.set_xlabel("Time (days)")
plt.title("Pressure Peaceman UserObject Mass Rate")
plt.grid()
# Creating a second y-axis for kg per second
ax2 = ax1.twinx()
y_min, y_max = ax1.get_ylim()
y_min_si = y_min / kgs_to_bpm
y_max_si = y_max / kgs_to_bpm
ax2.set_ylim(y_min_si, y_max_si)
ax2.set_ylabel("Mass Rate (kg s)")
#
#
# Pressure around well 58 bottom
fig, ax1 = plt.subplots(1, 1, figsize=(10, 6))
ax1.plot(
    df["time"] / 3600 / 24,
    df["p_well_58_bottom"] / 1e6 * MPa_to_psi,
    color="b",
    label="simulation",
)
ax1.plot(
    df_58_32["time_elapsed"] / 3600 / 24,
    df_58_32["pressure (psi)"],
    color="black",
    label="field",
)
ax1.legend()
ax1.set_ylim(bottom=0)
ax1.set_xlabel("Time (days)")
ax1.set_ylabel("Pressure (psi)")
# Creating a second y-axis for MPa
ax2 = ax1.twinx()
y_min, y_max = ax1.get_ylim()
y_min_si = y_min / MPa_to_psi
y_max_si = y_max / MPa_to_psi
ax2.set_ylim(y_min_si, y_max_si)
ax2.set_ylabel("Pressure (MPa)")
plt.title("Relative Pressure at Well 58 bottom")
#
#
# injection p_in pressures
p_in_columns = [col for col in df.columns if col.startswith("p_in_")]
num_columns = len(p_in_columns)
colors = cm.jet(np.linspace(0, 1, num_columns))

fig, ax1 = plt.subplots(1, 1, figsize=(10, 6))
for i, col in enumerate(p_in_columns):
    ax1.plot(
        df["time"] / 3600 / 24,
        df[col] / 1e6 * MPa_to_psi,
        color=colors[i],
        label=col,
    )
ax1.plot(
    df_30day_exp_press["time_elapsed"] / 3600 / 24,
    df_30day_exp_press["16A WELLHEAD PSI (PSI)"],
    "--k",
    label="field",
)
ax1.set_ylim(bottom=0)
ax1.legend(title="Stage")
ax1.set_xlabel("Time (days)")
ax1.set_ylabel("Injection Relative Pressure (psi)")
# Creating a second y-axis for MPa
ax2 = ax1.twinx()
y_min, y_max = ax1.get_ylim()
y_min_si = y_min / MPa_to_psi
y_max_si = y_max / MPa_to_psi
ax2.set_ylim(y_min_si, y_max_si)
ax2.set_ylabel("Injection Relative Pressure (MPa)")
plt.title("Relative Pressure at Well 16A injection points")

#
#
# production p_out pressures
p_out_columns = [col for col in df.columns if col.startswith("p_out_")]
num_columns = len(p_out_columns)
colors = cm.jet(np.linspace(0, 1, num_columns))

fig, ax1 = plt.subplots(1, 1, figsize=(10, 6))
for i, col in enumerate(p_out_columns):
    ax1.plot(
        df["time"] / 3600 / 24,
        df[col] / 1e6 * MPa_to_psi,
        color=colors[i],
        label=col,
    )
ax1.set_ylim(bottom=0)
ax1.legend(title="z-location (m)")
ax1.set_xlabel("Time (days)")
ax1.set_ylabel("Production Relative Pressure (psi)")
# Creating a second y-axis for MPa
ax2 = ax1.twinx()
y_min, y_max = ax1.get_ylim()
y_min_si = y_min / MPa_to_psi
y_max_si = y_max / MPa_to_psi
ax2.set_ylim(y_min_si, y_max_si)
ax2.set_ylabel("Production Relative Pressure (MPa)")
plt.title("Relative Pressure at Well 16B production points")

#
#
# injection t_in temperatures
t_in_columns = [col for col in df.columns if col.startswith("t_in_")]
num_columns = len(t_in_columns)
colors = cm.jet(np.linspace(0, 1, num_columns))
plt.figure(figsize=(10, 6))
for i, col in enumerate(t_in_columns):
    plt.plot(
        df["time"] / 3600 / 24,
        df[col],
        color=colors[i],
        label=col,
    )
plt.legend(title="Stage")
plt.xlabel("Time (days)")
plt.ylabel("Temperature (C)")
plt.title("Relative Temperature at Well 16A injection points")

#
#
# production t_out temepratures
t_out_columns = [col for col in df.columns if col.startswith("t_out_")]
num_columns = len(t_out_columns)
colors = cm.jet(np.linspace(0, 1, num_columns))
plt.figure(figsize=(10, 6))
for i, col in enumerate(t_out_columns):
    plt.plot(
        df["time"] / 3600 / 24,
        df[col],
        color=colors[i],
        label=col,
    )
plt.legend(title="Stage")
plt.xlabel("Time (days)")
plt.ylabel("Temperature (C)")
plt.title("Relative Temperature at Well 16B production points")

# -------------------------------------------------------------------------------q

plt.show()
