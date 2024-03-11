# AAD_4direction_code

Guidence

(1) Download raw data from https://zenodo.org/records/10803229 and copy it to the file rawdata

(2) Run allcode.m in Matlab (you should add EEGLAB to Matlab PATH)

(3) Run python code to do ASAD

(4) Statistic_analysis


File Structure

--AAD
      
      --analysis
         
          --matlab
              --code_env
                  --TRFs: the code of "3.1.	TRFs estimation"
                  --envelope_process_neu: the code of "3.2.	Speech stimulus reconstruction"
              --code_space
                  --preprocess_IIR: preprocess data to prepare for ASAD
          
          --python
              --code
                  --main.py: the code of 3.3 "ASAD"
                  --config.py: change the 5 line, "model_name = model_names[3]# # you could change the code to other models by only changing the number"
          
          --statistic_analysis
              --results: the results achieved from python code.
              --plot_fig4.m: plot figure 4.
      
      --preprocess
          --cuteeg.m: cut the precessed data from raw ear-EEG dara as described in 2.3
      
      --preprocess_data
        * no file now: you could get the data after runing cuteeg.m
      
      --rawdata
        * no file now: The raw data was released. Please download raw data from the following link: https://zenodo.org/records/10803229
      
      --allcode.m: To help you run our code, you could run "allcode.m" to do everything before ASAD (ASAD is python code rather than matlab code).
