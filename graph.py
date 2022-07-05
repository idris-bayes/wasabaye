import sys
import matplotlib.pyplot as plt
import ast
import pandas as pd
from sklearn import linear_model
from sklearn import datasets
from sklearn.datasets import make_moons
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import scale
from scipy.special import expit
import numpy as np
from functools import reduce
from itertools import groupby
from scipy.stats import gaussian_kde
from scipy.interpolate import make_interp_spline

# Remove consecutive duplicates
def removeDuplicates(xs):
  return [v for i, v in enumerate(xs) if i == 0 or v != xs[i-1]]

def main():
  arg  = sys.argv[1]
  f    = open("model-output.txt", "r")

  data = ast.literal_eval(f.read().replace('-Infinity', '-2e308')) #

  if arg in ["simLinRegr", "simLinRegrMB"]:
    xs = [xy[0] for xy in data]
    ys = [xy[1] for xy in data]
    plt.scatter(xs, ys)
    plt.xlabel('x data points')
    plt.ylabel('y data points')
    plt.show()
  if arg in ["mhLinRegrMB"]: # Remove duplicates from mh trace
    mus = removeDuplicates(data[0]) 
    cs  = removeDuplicates(data[1])
    fig1, axs1 = plt.subplots(nrows=1)
    axs1.set_xlabel("mu values", fontsize=12)
    axs1.set_ylabel("frequency")
    axs1.hist(mus,bins=25)
    fig2, axs2 = plt.subplots(nrows=1)
    axs2.set_xlabel("c values", fontsize=12)
    axs2.set_ylabel("frequency")
    axs2.hist(cs, bins=25)
    plt.show()
  if arg in ["smcLinRegrMB", "rmsmcLinRegrMB"]:
    mus = data[0]
    cs  = data[1]
    fig1, axs1 = plt.subplots(nrows=1)
    axs1.set_xlabel("mu values", fontsize=12)
    axs1.set_ylabel("frequency")
    axs1.hist(mus,bins=25)
    fig2, axs2 = plt.subplots(nrows=1)
    axs2.set_xlabel("c values", fontsize=12)
    axs2.set_ylabel("frequency")
    axs2.hist(cs, bins=25)
    plt.show()
if __name__ == "__main__":
  main()