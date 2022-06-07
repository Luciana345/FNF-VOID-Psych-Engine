function onStepHit()
  if curStep==1361 then
    objectPlayAnimation('crack','1st',false)
  end
  if curStep==1471 then
    setProperty('crowd.visible',false)
    setProperty('bg.visible',false)
  end
  if curStep==1696 then
    setProperty('bg.visible',true)
    setProperty('crowd2.visible',true)
  end
  if curStep==2112 then
    objectPlayAnimation('crack','2nd',false)
  end
  end