import cv2
import math
import numpy as np
import sys
import statistics
import argparse
import librosa
import decimal


datadir = "/data/movie/fmri/stimuli/"
datadir2 = "/data/movie/fmri/participants/adults/sarah_data/lancaster/"
#datadir = "/Users/sarah/Downloads/"

def frange(start, stop, step):
	while start<stop:
		yield round(float(start),2)
		start += decimal.Decimal(step)

def FrameCapture():
	parser = argparse.ArgumentParser()
	parser.add_argument('-m', action="store", dest='movie')
	parser.add_argument('-i', action="store", dest='sound_file', default="")
	args = parser.parse_args()

	with open(datadir2 + args.movie + "_start_duration_lancaster" + '.1D', 'r') as l:
		lines = l.readlines()
		start = []
		duration = []
		for x in lines:
			start.append(x.split('*')[0])
			duration.append(x.split(':')[1].split('\n')[0])

    # Path to video file 
	visual_stimuli = datadir + args.movie + '_visual_regressors.1D'
	path = datadir + args.sound_file
	vidObj = cv2.VideoCapture(path) 

	y, sr = librosa.load(args.sound_file, sr=48000)
	if not vidObj.isOpened():
		print("Error opening video")
    # Used as counter variable 

	count = 0
	success=1
	fps = vidObj.get(cv2.CAP_PROP_FPS) # frames per second
	length = int(librosa.get_duration(y, sr=sr) * fps)
    # checks whether frames were extracted 
	luminance = []
    
	while count < length-2 : 
		success, image = vidObj.read()
		Y = cv2.cvtColor(image, cv2.COLOR_BGR2YCrCb)[:,:,0] # luminance of image pixels
		std = np.std(Y) # standard deviation of luminance = contrast
		luminance.append(std)
		count+=1

	with open(visual_stimuli, 'w+') as file:
		timing = list(frange(0, int(librosa.get_duration(y, sr=sr)), 1/fps))
		for i, val in enumerate(start):
			dur_length = round(float(duration[i]),2) # eg. duration = 0.2
			idx_initial = min(range(len(timing)), key=lambda k: abs(timing[k]-round(float(val),2)))
			idx_final = (idx_initial + int(dur_length*fps)) # 0.2sec * 25frames = 5 indexes
			if float(duration[i]) > (1/fps):
				avg_luminance = statistics.mean(luminance[idx_initial:idx_final])
			else:
				avg_luminance = luminance[idx_initial]
			file.write('{}*{}:{}\n'.format(val, avg_luminance, duration[i]))
		file.close()
        
if __name__ == '__main__': 
    # Calling the function 
    FrameCapture()

