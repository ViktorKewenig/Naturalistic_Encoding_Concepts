import librosa
import argparse
from datetime import datetime
import statistics
import decimal

def frange(start, stop, step):
	while start<stop:
		yield round(float(start),2)
		start += decimal.Decimal(step)

def sound():
    parser = argparse.ArgumentParser(description="You want sound? We'll give you sound")
    parser.add_argument('-i', action="store", dest='sound_file', default="")
    parser.add_argument('-o', action="store", dest='output_type', default="afni")
    parser.add_argument('-m', action="store", dest='movie', default="afni")
    parser.add_argument('-r', action="store", dest='resolution', default="1s")
    args = parser.parse_args()
    # startTime = datetime.now()

    y, sr = librosa.load(args.sound_file, sr=48000)
    datadir = "/data/movie/fmri/stimuli/"
    datadir2 = "/data/movie/fmri/participants/adults/sarah_data/lancaster/"
    # datadir = "/Users/sarah/Downloads/"

    if args.resolution == "1s":
        hop_length = 48000
        timepoints = 1
    elif args.resolution == "100ms":
        hop_length = 4800
        timepoints = 10
    elif args.resolution == "10ms":
        hop_length = 480
        timepoints = 100

    rmse = librosa.feature.rms(y=y, hop_length=hop_length, frame_length=hop_length)
    times = [librosa.frames_to_time(tim, hop_length=hop_length, sr=sr) for tim in range(0, len(rmse[0]))]
    rmse = rmse[0]
    output = []
    print("==================")
    print("Let's see if this makes sense...")
    print('Movie duration: ', librosa.get_duration(y, sr=sr))
    print('If doing this every %s, we should have:' % args.resolution, int(librosa.get_duration(y, sr=sr)*timepoints), 'timepoints')
    print('Number of timepoints: ', len(times))

    if args.output_type == "afni":
        print('Time to output for AFNI')
        for i in range(0, len(times)):
            output.append(rmse[i])

        with open(datadir2 + args.movie + "_start_duration_lancaster" + '.1D', 'r') as l:
        	lines = l.readlines()
        	start = []
        	duration = []
        	for x in lines:
        		start.append(x.split('*')[0])
        		duration.append(x.split(':')[1].split('\n')[0])

        with open(datadir + args.movie + "_soundpower_afni" + '.1D', 'w+') as f:
        	timing=list(frange(0,len(output)-1, (1/timepoints)))
        	for i, val in enumerate(start):
        		dur_length = round(float(duration[i]),2)
        		idx_initial = timing.index(round(float(val),2))
        		idx_final = (idx_initial + int(dur_length*timepoints))
        		if float(duration[i]) > (1/timepoints):
        			avg_rmse = statistics.mean(output[idx_initial:idx_final])
        		else:
        			avg_rmse = output[idx_initial]
        		f.write('{}*{:.10f}:{}\n'.format(val, avg_rmse, duration[i]))
        	f.close()

    elif args.output_type == "context":
        print('Output for context word analysis')
        for i in range(0, len(times)):
            output.append(rmse[i])

        with open(args.sound_file.split("_")[0].split('/')[-1] + "_soundpower_context" + '.txt', 'w+') as f:
            for i, out in enumerate(output):
                f.write(str(out) + "," + str(i) + '\n')
            f.close()
    else:
        for i in range(0, len(times)):
            output.append([times[i], rmse[i]])

        with open(datadir + args.sound_file.split("_")[0] + "_soundpower_cdr" + '.csv', 'w+') as f:
            f.write('perp fROI time soundPower100ms' + '\n')
            for out in output:
                f.write('perp01 voxel01 ' + str(out[0]) + " " + str(out[1]) + '\n')
            f.close()

    # print('It took: ', datetime.now() - startTime)


if __name__ == "__main__":
    sound()

