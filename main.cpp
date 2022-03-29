#include <fstream>
#include <iostream>
#include <string>
#include <bits/stdc++.h>
#include <vector>

using namespace std;

int main(int argc, char* argv[]){

	if(argc < 5){
		cout<<"insufficient args provided\n";
		return -1;
	}

	ifstream image_file(argv[1], ios::in);
	ifstream query_file(argv[2], ios::in);
	int threshold = atoi(argv[3]);
	int topn = atoi(argv[4]);

	vector<int> TopNtriplets;

	int in_rows,in_cols;
	image_file>>in_rows;
	image_file>>in_cols;

	int input_img[in_rows][in_cols][3];

	for(int idx=0;idx<in_rows;idx++)
	{
		for(int jdx=0;jdx<in_cols;jdx++)
		{
			for(int kdx=0;kdx<3;kdx++)
			{
				image_file>>input_img[idx][jdx][kdx];
				//cerr<<input_img[idx][jdx][kdx]<<" ";
			}
		}
	}
	
	image_file.close();

	int q_rows,q_cols;
	query_file>>q_rows;
	query_file>>q_cols;

	int query_img[q_rows][q_cols][3];
	
	for(int idx=0;idx<q_rows;idx++)
	{
		for(int jdx=0;jdx<q_cols;jdx++)
		{
			for(int kdx=0;kdx<3;kdx++)
			{
				query_file>>query_img[idx][jdx][3];
			}
		}
	}

	query_file.close();
	
	//calculate topntriplets

	//assert(TopNtriplets.size() == topn * 3);
	ofstream output_file("output.txt", ios::out);
	for(int i=0;i<TopNtriplets.size();i+=3){
		output_file<<TopNtriplets[i]<<" "<<TopNtriplets[i+1]<<" "<<TopNtriplets[i+2]<<"\n";
	}
	output_file.close();
	return 0;
}
