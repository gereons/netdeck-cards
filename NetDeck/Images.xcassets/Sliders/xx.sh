

for dir in influence_slider.imageset mem_slider.imageset point_slider.imageset strength_slider.imageset trash_slider.imageset
do
    cd $dir
    for img in *.png
    do
        TARGET=$(basename $img .png)-d.png
        convert $img -channel RGB -negate $TARGET
    done
    cd ..
done
