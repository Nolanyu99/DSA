clear
clc
close all

%origin
lat0 = 51.537758;
lon0 = -0.011595;

lat = [
51.537758
51.538559
51.540135
51.541436
51.541705
51.544739
51.539375
51.538155
51.538448
51.540971
51.541118
51.540071
51.542018
51.542883
51.541214
51.540413
51.539566
51.538739
];

lon = [
-0.011595
-0.010013
-0.011382
-0.013236
-0.015492
-0.019684
-0.014644
-0.011495
-0.010295
-0.012778
-0.014240
-0.015001
-0.016213
-0.017918
-0.019824
-0.016427
-0.012644
-0.012138
];

names = {
"Marshgate"
"OPS"
"Aquatics Centre"
"UAL"
"Climbing Wall"
"Handball Club"
"London Stadium"
"Nine Pillar Bridge Sign"
"Nine Pillar Bridge Obstacle"
"Ginger Mint Eastbank"
"Tallow Bridge"
"Taverna in the Park"
"Carpenters Road Lock"
"Marshgate Lane North"
"Monier Bridge"
"Olympic Bell"
"Potato Dog"
"ArcelorMittal Orbit"
};


type = [
2
2
2
2
2
2
2
3
1
3
3
3
3
3
3
3
3
3
];

x = zeros(length(lat),1);
y = zeros(length(lat),1);

for i=1:length(lat)

dx = (lon(i)-lon0)*111320*cosd(lat0);
dy = (lat(i)-lat0)*111320;

x(i)=dx;
y(i)=dy;

end

figure

scatter(x,y,120,type,'filled')

text(x+5,y,names)

title("Real Map of QEOP Landmarks & Signal Points")
xlabel("X (meters)")
ylabel("Y (meters)")

grid on
axis equal


