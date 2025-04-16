
📊 Exploring the Facial Feedback Hypothesis using Facial Neuromuscular Electrical Stimulation (fNMES)

Overview

This repository contains the data preparation and analysis code for the study:

Efthimiou, T. N., Baker, J., Elsenaar, A., Mehu, M., & Korb, S. (2025).
Smiling and frowning induced by facial neuromuscular electrical stimulation (fNMES) modulate felt emotion and physiology.
Emotion, 25(1), 79–92.
https://doi.org/10.1037/emo0001408

The study explores the Facial Feedback Hypothesis using Facial Neuromuscular Electrical Stimulation (fNMES) to investigate how artificially induced facial expressions (smiling and frowning) affect emotional experience and physiological responses.

⸻

📑 Repository Contents
	•	data/ — Contains the preprocessed data file completed_frame.csv
	•	analysis.Rmd — R Markdown file with all data preparation, descriptive analyses, visualisations, and statistical models
  •	prepare_daya.Rmd - R Markedown to create the final dataset for analysis, this merges multiple sources of information. The data for this script can be found on OSF: https://osf.io/vbnyx
  •	Power Analysis - A folder containing the power analysis script and data

⸻

📈 Analyses Summary

The analysis workflow includes:
	•	Data import and preparation
	•	Loading libraries (tidyverse, lme4, ggstatsplot, etc.)
	•	Importing participant data and recoding factors
	•	Descriptive Statistics
	•	Demographics (gender, age, ethnicity, BMI)
	•	NMES intensity and discomfort ratings
	•	Histograms of positive affect, negative affect, alexithymia (TAS), and baseline mood
	•	Visualisations
	•	Interactive plots (via ggplot2 + plotly) for:
	•	Valence and arousal by stimulation condition and image presence
	•	Discomfort ratings by condition
	•	Statistical Modelling
	•	Linear mixed-effects models for:
	•	Valence and arousal with/without image presentation
	•	Model comparison to identify best fit
	•	Linear regressions exploring:
	•	Discomfort as a function of muscle, intensity, and mood
	•	Valence by muscle group

⸻

📚 How to Reproduce
	1.	Install Dependencies

Ensure you have the following R packages installed:

pacman::p_load(tidyverse, lme4, lmerTest, knitr, plotly, kableExtra, ggstatsplot, performance)

	2.	Run the Analysis

Open analysis.Rmd in RStudio and Knit to HTML.

⸻

🔬 Citation

If you use this code or build upon this work, please cite:

Efthimiou, T. N., Baker, J., Elsenaar, A., Mehu, M., & Korb, S. (2025).
Smiling and frowning induced by facial neuromuscular electrical stimulation (fNMES) modulate felt emotion and physiology.
Emotion, 25(1), 79–92.
https://doi.org/10.1037/emo0001408

⸻

