#--LOOPS 
for d in range(len(storm_list)):                        #-- dirs
    for f in inputfiles:  
        f63 = os.path.join(parent_dir,f)                #-- 63 files  
        with open(f63) as fin:        
            for line in fin:
                mynode = line.strip().split(' ')[0]     #--Test each line
                if mynode in nodes_list:     
                    f63_clip = os.path.join(parent_dir,"{0}_node_{1}.txt".format(mynode,param[f]))  
                    with open(f63_clip,'a') as fout:     #-- If passes, write to file
                        fout.write(line)
                
            
        