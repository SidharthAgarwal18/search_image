#include <stdio.h>
#include <iostream>
#include <fstream>
#include <map>
#include <bits/stdc++.h>
#include <math.h>

using namespace std;
__global__ 
void AverageFinder(int* dM, int *dQ, double *dR, int d_rows, int d_cols, int q_rows, int q_cols, int qavg, int th1, int angle)
{
	int avg = 0;
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	double x = i / d_cols;
	double y = i % d_cols;
	double leftmost, rightmost, topmost, bottommost;
	double sqrt2 = sqrt(2.0f);
	if (angle == 1){
		leftmost = x - (q_rows / sqrt2);
		rightmost = x + (q_cols / sqrt2);
		topmost = y + (q_cols / sqrt2) + (q_rows / sqrt2);
		bottommost = y;
	}

	else if(angle == 0){
		leftmost = x;
		rightmost = x + q_cols;
		topmost = y + q_rows;
		bottommost = y;
	}

	else if(angle == -1){
		rightmost = x + (q_cols / sqrt2) + (q_rows / sqrt2);
		leftmost = x;
		topmost = y + (q_rows / sqrt2);
		bottommost = y - (q_cols / sqrt2);
	}
	 
	printf("topmost:%f, bottommost:%f, leftmost:%f, rightmost:%f\n", topmost, bottommost, leftmost, rightmost);
	if(topmost >= d_rows || bottommost < 0 || leftmost < 0 || rightmost >= d_cols){
		dR[i] = -1.0f;
		return;
	}


	// printf("threadidx:%d\n",i);
	//add check to remove all for(int r = 0; r<q_rows; r++){
	// 	for(int c = 0; c<q_cols; c++){
	// 		int point = i + r*d_cols + c;
	// 		int pavg = 0;
	// 		for(int k = 0; k<3; k++){
	// 			pavg += dM[point * 3 + k];
	// 		}
	// 		avg += pavg / 3;
	// 	}
	// }

	// avg /= (q_rows * q_cols);
	// //printf("avg : %d\n",avg);
	// if(abs(qavg - avg) <= th1){
	// 	double total = 0;
	// 	for(int r = 0; r<q_rows; r++){
	// 		for(int c = 0; c<q_cols; c++){
	// 			for(int k = 0; k<3; k++){
	// 				long v = dM[i*3 + r*d_cols*3 + c*3 + k] - dQ[r*q_cols*3 + c*3 + k];
	// 				total += v * v;
	// 			}
	// 		}
	// 	}
	// 	total /= (q_cols*q_rows*3);
	// 	total = sqrt(total);
	// 	dR[i] = total;
	// 	printf("%d is close, RMSD : %f\n",i,total);
	// }
	// else{
	// 	dR[i] = -1.0f;
	// }overlaps that are outside data_image for all angles
	// for(int r = 0; r<q_rows; r++){
	// 	for(int c = 0; c<q_cols; c++){
	// 		int point = i + r*d_cols + c;
	// 		int pavg = 0;
	// 		for(int k = 0; k<3; k++){
	// 			pavg += dM[point * 3 + k];
	// 		}
	// 		avg += pavg / 3;
	// 	}
	// }

	// avg /= (q_rows * q_cols);
	// //printf("avg : %d\n",avg);
	// if(abs(qavg - avg) <= th1){
	// 	double total = 0;
	// 	for(int r = 0; r<q_rows; r++){
	// 		for(int c = 0; c<q_cols; c++){
	// 			for(int k = 0; k<3; k++){
	// 				long v = dM[i*3 + r*d_cols*3 + c*3 + k] - dQ[r*q_cols*3 + c*3 + k];
	// 				total += v * v;
	// 			}
	// 		}
	// 	}
	// 	total /= (q_cols*q_rows*3);
	// 	total = sqrt(total);
	// 	dR[i] = total;
	// 	printf("%d is close, RMSD : %f\n",i,total);
	// }
	// else{
	// 	dR[i] = -1.0f;
	// }

}

int main(int argc, char* argv[]){
	if(argc < 5){
		cout<<"insufficient args provided\n";
		return -1;
	}

	ifstream image_file(argv[1], ios::in);
	ifstream query_file(argv[2], ios::in);
	int threshold = atoi(argv[3]);
	int topn = atoi(argv[4]);

	int d_rows,d_cols;
	image_file>>d_rows;
	image_file>>d_cols;

	int *input_img = new int[d_rows * d_cols * 3];

	for(int idx=0; idx<d_rows; idx++){
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

	int *query_img = new int[q_rows * q_cols * 3];
	
	for(int idx=0;idx<q_rows;idx++){
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
	for(int i=0; i<q_rows * q_cols * 3; i+=3){
		qavg += (query_img[i] + query_img[i+1] + query_img[i+2])/3;
	}
	qavg /= (q_cols * q_rows);
	// cout<<"qavg :"<<qavg<<'\n';

	int th1 = 1;
	
	double *dR;
	cudaMalloc(&dR, N * sizeof(double));

	//kernel invocation
	AverageFinder<<<(N + 255)/256,256>>>(dM, dQ, dR, d_rows, d_cols, q_rows, q_cols, qavg, th1, 0);
	cudaDeviceSynchronize();
	AverageFinder<<<(N + 255)/256,256>>>(dM, dQ, dR, d_rows, d_cols, q_rows, q_cols, qavg, th1, 1);
	cudaDeviceSynchronize();
	AverageFinder<<<(N + 255)/256,256>>>(dM, dQ, dR, d_rows, d_cols, q_rows, q_cols, qavg, th1, -1);
	cudaDeviceSynchronize();
	//getback from the kernel
	map<int, double> Topn;
	double *R = new double[N];
	cudaMemcpy(R, dR, N * sizeof(double), cudaMemcpyDeviceToHost);

	cudaFree(dR);
	cudaFree(dM);
	cudaFree(dQ);

	//calculate topntriplets
	// for(int i=0; i<N; i++){
	// 	if(Topn.size() < topn){
	// 		Topn.emplace_back(R[i], i);
	// 		sort(Topn.begin(), Topn.end());
	// 	}
	// 	else{
	// 		if(Topn[topn-1].first > R[i]){
	// 			Topn.emplace_back(R[i], i);
	// 			sort(Topn.begin(), Topn.end());
	// 			Topn.pop_back();
	// 		}
	// 	}
	// }


	ofstream output_file("output.txt", ios::out);
	output_file.close();
	return 0;
}
