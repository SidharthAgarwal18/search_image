#include <fstream>
#include <iostream>
#include <string>
#include <bits/stdc++.h>
#include <vector>

using namespace std;

int main(int argc, char*[] argv){

	if(argc < 5){
		cout<<"insufficient args provided\n";
		return -1;
	}

	ifstream image_file(argv[1], ios::in);
	ifstream query_file(argv[2], ios::in);
	int threshold = atoi(argv[3]);
	int topn = atoi(argv[4]);

	vector<int> TopNtriplets;

	//take input
	
	image_file.close();
	query_file.close();
	
	//calculate topntriplets

	assert(TopNtriplets.size() == topn * 3);
	ofstream output_file("output.txt", ios::out);
	for(int i=0;i<TopNtriplets.size();i+=3){
		output_file<<TopNtriplets[i]<<" "<<TopNtriplets[i+1]<<" "<<TopNtriplets[i+2]<<"\n";
	}
	output_file.close();
	return 0;
}
