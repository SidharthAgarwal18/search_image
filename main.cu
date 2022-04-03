#include <stdio.h>
#include <iostream>
#include <fstream>
#include <map>
#include <bits/stdc++.h>
#include <math.h>
#include <queue>
#include <vector>
#include<string>

#define PI 3.141592 

using namespace std;

__device__
double distbtw(double a, double b, double c, double d)
{
	double x = (a-c) * (a-c);
	double y = (b-d) * (b-d);
	return sqrt(x + y);
}
__global__ 
void AverageFinder(int* dM, int *dQ, double *dR, int d_rows, int d_cols, int q_rows, int q_cols, int qavg, int th1, int angle)
{
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	double y = i / d_cols;
	double x = i % d_cols;
	double leftmost, rightmost, topmost, bottommost;
	double sqrt2 = sqrt(2.0f);
	if (angle == 1){
		leftmost = x - ((q_rows - 1)  / sqrt2);
		rightmost = x + ((q_cols - 1) / sqrt2);
		topmost = y + ((q_cols - 1) / sqrt2) + ((q_rows - 1) / sqrt2);
		bottommost = y;
	}

	else if(angle == 0){
		leftmost = x;
		rightmost = x + q_cols - 1;
		topmost = y + q_rows - 1;
		bottommost = y;
	}

	else if(angle == -1){
		rightmost = x + ((q_cols - 1) / sqrt2) + ((q_rows - 1)/ sqrt2);
		leftmost = x;
		topmost = y + ((q_rows - 1) / sqrt2);
		bottommost = y - ((q_cols - 1) / sqrt2);
	}
	 
	// printf("topmost:%f, bottommost:%f, leftmost:%f, rightmost:%f\n", topmost, bottommost, leftmost, rightmost);
	if(topmost >= d_rows || bottommost < 0 || leftmost < 0 || rightmost >= d_cols){
		dR[i] = -1.0f;
		return;
	}

	int avg = 0;
	for(int r = bottommost; r <= topmost; r++){
		for(int c = leftmost; c <= rightmost; c++){
			int pavg = 0;
			int point = r * d_cols + c;
			for(int k = 0; k < 3; k++){
				pavg += dM[point * 3 + k];
			}
			avg += pavg/3;
		}
	}
	avg /= ((topmost - bottommost + 1) * (rightmost - leftmost + 1));
	// printf("threadidx:%d avg:%d\n",i, avg);
	if(abs(qavg - avg) <= th1){
		double total = 0;
		for(int r = 0; r<q_rows; r++){
			for(int c = 0; c<q_cols; c++){
				double baseang;
				if(angle == 1)
					baseang = 45 * PI / 180;
				else if(angle == -1)
					baseang = -45 * PI / 180;
				else if(angle == 0)
					baseang = 0;
				double d = distbtw(r + x, c + y, x, y);
				double ang = baseang + atan2((double)r, (double)c);
				double rx = x + cos(ang) * d;
				double ry = y + sin(ang) * d;
				double ceilrx = ceil(rx), floorrx = floor(rx), ceilry = ceil(ry), floorry = floor(ry);
				double colorR, colorG, colorB;
				if(((ceilrx - rx) > 1e-10 && (rx - floorrx) > 1e-10)|| ((ry - floorry) > 1e-10 && (ceilry - ry) > 1e-10)){
					//bilinear interpolation
					// printf("%d doing bilinear interpolation, baseang%f ang%f d:%f ceilrx:%f floorrx:%f rx:%f ceilry:%f floorry:%f ry:%f\n", i, baseang, ang, d, ceilrx, floorrx, rx, ceilry, floorry, ry);
					colorR = dM[(int)(floorry * d_cols + floorrx)*3]*(ceilrx - rx)*(ceilry - ry) + dM[(int)(floorry * d_cols + ceilrx)*3]*(rx - floorrx)*(ceilry - ry) + dM[(int)(ceilry * d_cols + floorrx)*3]*(ceilrx - rx)*(ry - floorry) + dM[(int)(ceilry * d_cols + ceilrx)*3]*(rx - floorrx)*(ry - floorry);
					colorG = dM[(int)(1 + (floorry * d_cols + floorrx)*3)]*(ceilrx - rx)*(ceilry - ry) + dM[(int)(1 + (floorry * d_cols + ceilrx)*3)]*(rx - floorrx)*(ceilry - ry) + dM[(int)(1 + (ceilry * d_cols + floorrx)*3)]*(ceilrx - rx)*(ry - floorry) + dM[(int)(1 + (ceilry * d_cols + ceilrx)*3)]*(rx - floorrx)*(ry - floorry);
					colorB = dM[(int)(2 + (floorry * d_cols + floorrx)*3)]*(ceilrx - rx)*(ceilry - ry) + dM[(int)(2 + (floorry * d_cols + ceilrx)*3)]*(rx - floorrx)*(ceilry - ry) + dM[(int)(2 + (ceilry * d_cols + floorrx)*3)]*(ceilrx - rx)*(ry - floorry) + dM[(int)(2 + (ceilry * d_cols + ceilrx)*3)]*(rx - floorrx)*(ry - floorry);

				}
				else{
					// printf("%d doing normal interpolation, baseang%f ang%f ceilrx:%f floorrx:%f rx:%f ceilry:%f floorry:%f ry:%f\n", i, baseang, ang, ceilrx, floorrx, rx, ceilry, floorry, ry);
					colorR = dM[(int)(ry * d_cols + rx)*3];
					colorG = dM[(int)(1 + (ry * d_cols + rx)*3)];
					colorB = dM[(int)(2 + (ry * d_cols + rx)*3)];
				}
				double diffR = colorR - dQ[(r * q_cols + c)*3];
				double diffG = colorG - dQ[1 + (r * q_cols + c)*3];
				double diffB = colorB - dQ[2 + (r * q_cols + c)*3];
				total += (diffR*diffR + diffG*diffG + diffB*diffB);
			}
		}
		total /= (q_cols*q_rows*3);
		total = sqrt(total);
		dR[i] = total;
		//printf("%d (%f,%f) with avg:%d is close, RMSD:%f\n",i,x,y,avg,total);
	}
	else{
		// printf("%d (%f,%f) with avg:%d is not close\n",i,x,y,avg);
		dR[i] = -1.0f;
	}
}

void calcTopn(priority_queue<pair<double, vector<int> > > &Topn, double *dR, int N, int topn, int angle,int thresh){
	for(int i=0;i<N;i++){
		if(Topn.size() >= topn && dR[i]>=0 && dR[i]<=thresh){
			//cout<<"got:"<<i<<" "<<dR[i]<<" "<<angle<<"\n";
			pair<double, vector<int> > topele = Topn.top();
			if(topele.first > dR[i]){
				Topn.pop();
				vector<int> temp;
				temp.push_back(i);
				temp.push_back(angle);
				Topn.push(make_pair(dR[i], temp));
			}
		}
		else if(dR[i]>=0 && dR[i]<=thresh){
			//cout<<"got:"<<i<<" "<<dR[i]<<" "<<angle<<"\n";
			vector<int> temp;
			temp.push_back(i);
			temp.push_back(angle);
			Topn.push(make_pair(dR[i], temp));
		}
	}
}

int main(int argc, char* argv[]){
	if(argc < 6){
		cout<<"insufficient args provided\n";
		return -1;
	}

	ifstream image_file(argv[1], ios::in);
	ifstream query_file(argv[2], ios::in);
	int threshold1 = atoi(argv[4]); 		// for summation filtering..
	int threshold2 = atoi(argv[3]);			// for rdmsa
	int topn = atoi(argv[5]);

	int d_rows,d_cols;
	image_file>>d_rows;
	image_file>>d_cols;

	//cerr<<"break1\n";

	int *input_img = new int[d_rows * d_cols * 3];

	for(int idx=d_rows-1; idx>=0; idx--){
		for(int jdx=0; jdx<d_cols; jdx++){
			for(int kdx=0; kdx<3; kdx++){
				image_file>>input_img[idx*d_cols*3 + jdx*3 + kdx];
			}
		}
	}
	image_file.close();

	int q_rows,q_cols;
	query_file>>q_rows;
	query_file>>q_cols;

	//cerr<<"break2\n";
	int *query_img = new int[q_rows * q_cols * 3];
	
	for(int idx=q_rows-1;idx>=0;idx--){
		for(int jdx=0;jdx<q_cols;jdx++){
			for(int kdx=0;kdx<3;kdx++){
				query_file>>query_img[idx*q_cols*3 + jdx*3 + kdx];
			}
		}
	}

	query_file.close();

	//memory allocation for gpu
	int *dM, *dQ;
	cudaMalloc(&dM, d_rows*d_cols * 3 * sizeof(int));
	cudaMalloc(&dQ, q_rows*q_cols * 3 * sizeof(int));
	cudaMemcpy(dM, input_img, d_rows * d_cols * 3 * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dQ, query_img, q_rows * q_cols * 3 * sizeof(int), cudaMemcpyHostToDevice);

	//get query imae avg
	// int N = (d_rows - q_rows + 1) * (d_cols - q_cols + 1);
	int N = d_rows * d_cols;
	int qavg = 0;
	int th1 = threshold1;
	for(int i=0; i<q_rows * q_cols * 3; i+=3){
		qavg += (query_img[i] + query_img[i+1] + query_img[i+2])/3;
	}
	qavg /= (q_cols * q_rows);
	//cout<<"qavg :"<<qavg<<'\n';
	//cout<<"threshold1:"<<th1<<" threshold2:"<<threshold2<<" topn:"<<topn<<"\n";


	priority_queue<pair<double, vector<int> > > Topn;
	
	double *dR;
	double *R = new double[N];
	cudaMalloc(&dR, N * sizeof(double));

	//kernel invocation
	AverageFinder<<<(N + 255)/256,256>>>(dM, dQ, dR, d_rows, d_cols, q_rows, q_cols, qavg, th1, 0);
	cudaDeviceSynchronize();
	cudaMemcpy(R, dR, N * sizeof(double), cudaMemcpyDeviceToHost);
	calcTopn(Topn,R,N,topn,0,threshold2);

	AverageFinder<<<(N + 255)/256,256>>>(dM, dQ, dR, d_rows, d_cols, q_rows, q_cols, qavg, th1, 1);
	cudaDeviceSynchronize();
	cudaMemcpy(R, dR, N * sizeof(double), cudaMemcpyDeviceToHost);
	calcTopn(Topn,R,N,topn,1,threshold2);

	AverageFinder<<<(N + 255)/256,256>>>(dM, dQ, dR, d_rows, d_cols, q_rows, q_cols, qavg, th1, -1);
	cudaDeviceSynchronize();
	cudaMemcpy(R, dR, N * sizeof(double), cudaMemcpyDeviceToHost);			// Sidharth: optimize this
	calcTopn(Topn,R,N,topn,-1,threshold2);

	cudaFree(dR);
	cudaFree(dM);
	cudaFree(dQ);

	
	vector<vector<int> > ans;
	while(Topn.size()>0)
	{
		ans.push_back(Topn.top().second);
		//cerr<<Topn.top().first<<"\n";
		Topn.pop();
	}

	ofstream output_file("output.txt", ios::out);

	for(int idx=ans.size()-1;idx>=0;idx--)
	{
		output_file << ans[idx][0]/d_cols;
		output_file << " ";
		output_file << ans[idx][0]%d_cols;
		output_file << " ";

		if(int(ans[idx][1])==1) output_file << "45";
		else if(int(ans[idx][1])==-1) output_file << "-45";
		else output_file << "0";

		output_file << "\n";
	}
	output_file.close();
	return 0;
}