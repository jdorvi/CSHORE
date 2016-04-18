def main():
    import subprocess
    import datetime.datetime as dt
    x = dt.now()
    python = "python"
    function = "getstationoutput_ontario_crude.py"
    subprocess.Popen([python,
                      function,
                      "0"])
    subprocess.Popen([python,
                      function,
                      "1"])
    subprocess.Popen([python,
                      function,
                      "2"])
    subprocess.Popen([python,
                      function,
                      "3"])
    subprocess.Popen([python,
                      function,
                      "4"]).wait()
    y = dt.now()
    print("Total run time: "+str(y-x))
if __name__ == '__main__':
    main()
