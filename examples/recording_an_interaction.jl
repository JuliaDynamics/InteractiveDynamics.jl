# Use this simple script to record an interaction on an opened scene

framerate = 10
total_time = 30 # in seconds
framen = framerate*total_time

record(scene, "name.mp4"; framerate = framerate) do io
    for i = 1:framen
        sleep(1/framerate)
        recordframe!(io)
    end
end
