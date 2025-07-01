nim:
	nim c -d:release --app:staticLib wmc.nim 

all:
	#nim cpp -d:release --app:staticLib wmc.nim 
	nim c -d:release --app:staticLib wmc.nim 
	#gcc -Wno-discarded-qualifiers  -o tch tch.c libconvexhull_ref.a
	#g++ -o testCH testCH.cpp watermanCH.cpp -L. -lwmc
	./testCH
