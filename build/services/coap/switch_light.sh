if [ $1 -eq 0 ]; then
  echo "Light Off"
  exit
elif [ $1 -eq 1 ]; then
  echo "Light On"
  exit
fi
echo "Failed to swith the light: only 1 or 0 allowed as input"