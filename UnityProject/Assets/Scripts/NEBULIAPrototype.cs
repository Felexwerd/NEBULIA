using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections.Generic;

public class NEBULIAPrototype : MonoBehaviour
{
    int gold = 420, crystals = 12, food = 86, wood = 120, tavernLevel = 1, farmLevel = 1, buildingsBuilt = 0;
    int heroesOwned = 2, questsCompleted = 0;
    bool questClaimed = false;
    Text resources, status, level;
    Font font;
    Light sunLight;
    Camera villageCamera;
    Vector2 lastPointerPosition;
    float lastPinchDistance;
    float dayClock = 0.22f;
    float saveClock;
    readonly List<Material> materials = new List<Material>();
    readonly List<Transform> residents = new List<Transform>();
    readonly List<Vector3> residentHomes = new List<Vector3>();
    float playClock;

    void Start()
    {
        Application.targetFrameRate = 60;
        LoadGame();
        BuildVillage();
        RestorePlayerBuildings();
        BuildHUD();
        InvokeRepeating(nameof(Income), 5, 5);
        Refresh();
    }

    Material MakeMat(Color c)
    {
        var shader = Shader.Find("Standard");
        var m = new Material(shader);
        m.color = c; materials.Add(m); return m;
    }

    void Box(string n, Vector3 p, Vector3 s, Material m)
    {
        var o = GameObject.CreatePrimitive(PrimitiveType.Cube);
        o.name = n; o.transform.position = p; o.transform.localScale = s;
        o.GetComponent<Renderer>().sharedMaterial = m;
    }

    void BuildVillage()
    {
        var grass=MakeMat(new Color(.24f,.49f,.37f));
        var road=MakeMat(new Color(.78f,.68f,.52f));
        var water=MakeMat(new Color(.18f,.63f,.79f));
        var wall=MakeMat(new Color(.94f,.79f,.63f));
        var red=MakeMat(new Color(.72f,.29f,.34f));
        var blue=MakeMat(new Color(.26f,.43f,.68f));
        var woodMat=MakeMat(new Color(.36f,.20f,.16f));
        var leaves=MakeMat(new Color(.25f,.58f,.39f));
        var leafLight=MakeMat(new Color(.38f,.70f,.46f));
        var windowMat=MakeMat(new Color(1f,.77f,.36f));
        var stone=MakeMat(new Color(.58f,.61f,.62f));
        var flowerPink=MakeMat(new Color(.96f,.55f,.72f));
        var flowerGold=MakeMat(new Color(1f,.79f,.38f));
        Box("Meadow",new Vector3(0,-.35f,0),new Vector3(34,.5f,26),grass);
        Box("Main road",new Vector3(0,-.06f,0),new Vector3(3.4f,.08f,26),road);
        Box("Crossroad",new Vector3(-3.2f,-.05f,1.7f),new Vector3(19,.09f,2.5f),road);
        Box("River",new Vector3(12,-.02f,0),new Vector3(3.2f,.1f,26),water);
        for(int i=-5;i<=5;i++) Box("Bridge plank",new Vector3(10.1f,.06f,i*.42f),new Vector3(3.4f,.12f,.34f),woodMat);
        House("Moonlit Tavern",new Vector3(-7.5f,0,4.8f),wall,red,woodMat);
        House("Sunrise Farm",new Vector3(6.5f,0,5.4f),wall,blue,woodMat);
        House("Craftsman's Hall",new Vector3(-7,0,-5.4f),wall,blue,woodMat);
        House("Village Cottage",new Vector3(5.8f,0,-5.8f),wall,red,woodMat);
        // Cozy details make the village read as a lived-in fantasy settlement.
        for(int i=0;i<8;i++){
            float x=-10.5f+i*3.0f;
            if(Mathf.Abs(x)<3.8f) continue;
            Box("Roadside stepping stone",new Vector3(x,.015f,0),new Vector3(.52f,.04f,.34f),stone);
            Box("Lantern post",new Vector3(x,.65f,-1.9f),new Vector3(.13f,1.3f,.13f),woodMat);
            var glow=GameObject.CreatePrimitive(PrimitiveType.Sphere); glow.name="Warm lantern";
            glow.transform.position=new Vector3(x,1.35f,-1.9f); glow.transform.localScale=Vector3.one*.28f;
            glow.GetComponent<Renderer>().sharedMaterial=windowMat;
        }
        for(int i=0;i<30;i++){
            float x=-15f+(i*2.31f)%29f, z=-10.5f+(i*1.79f)%21f;
            if(Mathf.Abs(x)<4.2f || Mathf.Abs(x-12f)<3.2f || (Mathf.Abs(z)<2f && Mathf.Abs(x)<10f)) continue;
            var bloom=GameObject.CreatePrimitive(PrimitiveType.Sphere); bloom.name="Meadow flower";
            bloom.transform.position=new Vector3(x,.12f,z); bloom.transform.localScale=new Vector3(.13f,.10f,.13f);
            bloom.GetComponent<Renderer>().sharedMaterial=(i%2==0)?flowerPink:flowerGold;
        }
        for(int i=0;i<22;i++){
            float x=-15+(i*1.73f)%28, z=-11+(i*3.17f)%22;
            if(Mathf.Abs(x)<3||Mathf.Abs(x-12)<3) continue;
            var trunk=GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            trunk.transform.position=new Vector3(x,.55f,z); trunk.transform.localScale=new Vector3(.22f,.55f,.22f);
            trunk.GetComponent<Renderer>().sharedMaterial=woodMat;
            var crown=GameObject.CreatePrimitive(PrimitiveType.Sphere);
            crown.transform.position=new Vector3(x,1.45f,z); crown.transform.localScale=Vector3.one*1.25f;
            crown.GetComponent<Renderer>().sharedMaterial=leaves;
            var crown2=GameObject.CreatePrimitive(PrimitiveType.Sphere);
            crown2.name="Tree sunlit foliage"; crown2.transform.position=new Vector3(x-.28f,1.62f,z+.18f);
            crown2.transform.localScale=Vector3.one*.78f; crown2.GetComponent<Renderer>().sharedMaterial=leafLight;
        }
        for(int i=0;i<7;i++){
            var v=GameObject.CreatePrimitive(PrimitiveType.Capsule);
            v.name="Villager · "+(i+1); v.transform.position=new Vector3(-4+i*1.25f,.62f,Mathf.Sin(i*1.7f)*2);
            v.transform.localScale=new Vector3(.42f,.62f,.42f);
            v.GetComponent<Renderer>().sharedMaterial=MakeMat(Color.Lerp(new Color(.48f,.72f,.91f),new Color(.94f,.53f,.64f),i/6f));
            var h=GameObject.CreatePrimitive(PrimitiveType.Sphere);
            h.name="Villager head"; h.transform.SetParent(v.transform,false);
            h.transform.localPosition=new Vector3(0,1.22f,0); h.transform.localScale=Vector3.one*.48f;
            h.GetComponent<Renderer>().sharedMaterial=wall;
            residents.Add(v.transform); residentHomes.Add(v.transform.position);
        }
        var lightObj=new GameObject("Afternoon sunlight"); var light=lightObj.AddComponent<Light>();
        light.type=LightType.Directional; light.intensity=1.35f; light.color=new Color(1,.86f,.71f);
        sunLight = light;
        lightObj.transform.rotation=Quaternion.Euler(48,-32,0);
        RenderSettings.ambientLight=new Color(.62f,.69f,.76f);
        var camObj=new GameObject("Village Camera"); camObj.tag="MainCamera";
        var cam=camObj.AddComponent<Camera>(); villageCamera=cam;
        cam.transform.position=new Vector3(0,20,-23);
        cam.transform.rotation=Quaternion.Euler(43,0,0); cam.orthographic=true; cam.orthographicSize=14.5f;
        cam.backgroundColor=new Color(.55f,.76f,.87f); cam.clearFlags=CameraClearFlags.SolidColor;
    }

    void House(string n,Vector3 p,Material wall,Material roof,Material woodMat)
    {
        Box(n+" walls",p+new Vector3(0,1.1f,0),new Vector3(3.1f,2.1f,2.7f),wall);
        // Two sloped roof planes instead of a flat block.
        var leftRoof=GameObject.CreatePrimitive(PrimitiveType.Cube); leftRoof.name=n+" left roof slope";
        leftRoof.transform.position=p+new Vector3(-.78f,2.48f,0); leftRoof.transform.localScale=new Vector3(1.95f,.28f,3.25f);
        leftRoof.transform.rotation=Quaternion.Euler(0,0,-27f); leftRoof.GetComponent<Renderer>().sharedMaterial=roof;
        var rightRoof=GameObject.CreatePrimitive(PrimitiveType.Cube); rightRoof.name=n+" right roof slope";
        rightRoof.transform.position=p+new Vector3(.78f,2.48f,0); rightRoof.transform.localScale=new Vector3(1.95f,.28f,3.25f);
        rightRoof.transform.rotation=Quaternion.Euler(0,0,27f); rightRoof.GetComponent<Renderer>().sharedMaterial=roof;
        Box(n+" door",p+new Vector3(0,.55f,-1.37f),new Vector3(.6f,1.1f,.1f),woodMat);
        Box(n+" porch",p+new Vector3(0,.1f,-1.65f),new Vector3(1.8f,.15f,.8f),woodMat);
        var leftWindow=GameObject.CreatePrimitive(PrimitiveType.Cube); leftWindow.name=n+" left glowing window";
        leftWindow.transform.position=p+new Vector3(-.92f,1.25f,-1.38f); leftWindow.transform.localScale=new Vector3(.48f,.58f,.08f);
        leftWindow.GetComponent<Renderer>().sharedMaterial=MakeMat(new Color(.98f,.75f,.38f));
        var rightWindow=GameObject.CreatePrimitive(PrimitiveType.Cube); rightWindow.name=n+" right glowing window";
        rightWindow.transform.position=p+new Vector3(.92f,1.25f,-1.38f); rightWindow.transform.localScale=new Vector3(.48f,.58f,.08f);
        rightWindow.GetComponent<Renderer>().sharedMaterial=leftWindow.GetComponent<Renderer>().sharedMaterial;
        Box(n+" signboard",p+new Vector3(0,2.0f,-1.52f),new Vector3(1.1f,.28f,.10f),woodMat);
    }

    void BuildHUD()
    {
        new GameObject("EventSystem",typeof(EventSystem),typeof(StandaloneInputModule));
        var co=new GameObject("Mobile HUD",typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));
        var c=co.GetComponent<Canvas>(); c.renderMode=RenderMode.ScreenSpaceOverlay;
        var sc=co.GetComponent<CanvasScaler>(); sc.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;
        sc.referenceResolution=new Vector2(1080,1920); sc.matchWidthOrHeight=.5f;
        font=Resources.GetBuiltinResource<Font>("Arial.ttf");
        Panel(co.transform,new Vector2(.5f,1),new Vector2(0,-100),new Vector2(1000,155),new Color(.07f,.11f,.2f,.91f));
        Label(co.transform,"NEBULIA",new Vector2(.5f,1),new Vector2(-350,-55),new Vector2(260,65),44,new Color(.86f,.91f,1),TextAnchor.MiddleLeft);
        resources=Label(co.transform,"",new Vector2(.5f,1),new Vector2(130,-85),new Vector2(660,65),24,Color.white,TextAnchor.MiddleRight);
        Panel(co.transform,new Vector2(.5f,.5f),new Vector2(0,360),new Vector2(700,95),new Color(.08f,.13f,.22f,.78f));
        Label(co.transform,"✦  LUMENFALL VILLAGE  ✦",new Vector2(.5f,.5f),new Vector2(0,360),new Vector2(690,80),30,new Color(1,.85f,.58f),TextAnchor.MiddleCenter);
        Panel(co.transform,new Vector2(.5f,0),new Vector2(0,190),new Vector2(1000,270),new Color(.07f,.11f,.2f,.94f));
        status=Label(co.transform,"Your village is waking up...",new Vector2(.5f,0),new Vector2(0,285),new Vector2(900,55),24,new Color(.78f,.86f,.98f),TextAnchor.MiddleCenter);
        level=Label(co.transform,"Moonlit Tavern · Lv. 1",new Vector2(.5f,0),new Vector2(-210,205),new Vector2(470,55),27,Color.white,TextAnchor.MiddleCenter);
        AddButton(co.transform,"UPGRADE · 100 G",new Vector2(.5f,0),new Vector2(300,205),new Vector2(300,66),new Color(.73f,.39f,.85f),Upgrade);
        AddButton(co.transform,"QUESTS",new Vector2(.5f,0),new Vector2(-300,115),new Vector2(260,62),new Color(.23f,.53f,.76f),ShowQuest);
        AddButton(co.transform,"HEROES",new Vector2(.5f,0),new Vector2(0,115),new Vector2(260,62),new Color(.23f,.53f,.76f),ShowHeroes);
        AddButton(co.transform,"RECRUIT",new Vector2(.5f,0),new Vector2(300,115),new Vector2(260,62),new Color(.88f,.62f,.25f),Recruit);
        AddButton(co.transform,"SAVE",new Vector2(.5f,0),new Vector2(-300,35),new Vector2(260,52),new Color(.20f,.48f,.38f),()=>{SaveGame();status.text="Village saved on this device.";});
        AddButton(co.transform,"TRADE",new Vector2(.5f,0),new Vector2(0,35),new Vector2(260,52),new Color(.20f,.48f,.38f),TradeResources);
        AddButton(co.transform,"BUILD",new Vector2(.5f,0),new Vector2(300,35),new Vector2(260,52),new Color(.65f,.43f,.28f),BuildNewBuilding);
    }

    RectTransform Panel(Transform p,Vector2 anchor,Vector2 pos,Vector2 size,Color color)
    {
        var o=new GameObject("Panel",typeof(RectTransform),typeof(Image)); o.transform.SetParent(p,false);
        var r=o.GetComponent<RectTransform>(); r.anchorMin=r.anchorMax=anchor; r.anchoredPosition=pos; r.sizeDelta=size;
        o.GetComponent<Image>().color=color; return r;
    }

    Text Label(Transform p,string value,Vector2 anchor,Vector2 pos,Vector2 size,int fs,Color color,TextAnchor align)
    {
        var o=new GameObject("Label",typeof(RectTransform),typeof(Text)); o.transform.SetParent(p,false);
        var r=o.GetComponent<RectTransform>(); r.anchorMin=r.anchorMax=anchor; r.anchoredPosition=pos; r.sizeDelta=size;
        var t=o.GetComponent<Text>(); t.text=value; t.font=font; t.fontSize=fs; t.color=color; t.alignment=align;
        t.horizontalOverflow=HorizontalWrapMode.Wrap; t.verticalOverflow=VerticalWrapMode.Overflow; return t;
    }

    void AddButton(Transform p,string title,Vector2 anchor,Vector2 pos,Vector2 size,Color color,UnityEngine.Events.UnityAction action)
    {
        var r=Panel(p,anchor,pos,size,color); var b=r.gameObject.AddComponent<Button>(); b.onClick.AddListener(action);
        var t=Label(r,title,new Vector2(.5f,.5f),Vector2.zero,size,22,Color.white,TextAnchor.MiddleCenter);
        t.resizeTextForBestFit=true; t.resizeTextMinSize=14; t.resizeTextMaxSize=24;
    }

    void Update()
    {
        dayClock += Time.deltaTime / 180f;
        if (dayClock >= 1f) dayClock -= 1f;
        if (sunLight != null)
        {
            float angle = dayClock * 360f - 90f;
            sunLight.transform.rotation = Quaternion.Euler(angle, -32f, 0f);
            float daylight = Mathf.Clamp01(Mathf.Sin(dayClock * Mathf.PI));
            sunLight.intensity = Mathf.Lerp(0.18f, 1.35f, daylight);
            sunLight.color = Color.Lerp(new Color(.42f,.52f,.82f), new Color(1f,.86f,.71f), daylight);
            RenderSettings.ambientLight = Color.Lerp(new Color(.13f,.17f,.29f), new Color(.62f,.69f,.76f), daylight);
        }
        AnimateVillageLife();
        HandleCameraInput();
        saveClock += Time.deltaTime;
        if (saveClock >= 30f) { SaveGame(); saveClock = 0f; }
    }

    void AnimateVillageLife()
    {
        playClock += Time.deltaTime;
        for (int i = 0; i < residents.Count; i++)
        {
            Transform villager = residents[i];
            if (villager == null) continue;
            Vector3 home = residentHomes[i];
            float phase = playClock * (.48f + i * .035f) + i * 1.7f;
            float walkX = Mathf.Sin(phase) * 1.05f;
            float walkZ = Mathf.Cos(phase * .73f) * .68f;
            villager.position = new Vector3(home.x + walkX, home.y + Mathf.Abs(Mathf.Sin(phase * 2.4f)) * .035f, home.z + walkZ);
            Vector3 direction = new Vector3(Mathf.Cos(phase), 0f, -Mathf.Sin(phase * .73f) * .5f);
            if (direction.sqrMagnitude > .01f) villager.rotation = Quaternion.Slerp(villager.rotation, Quaternion.LookRotation(direction), Time.deltaTime * 3f);
        }
    }

    void HandleCameraInput()
    {
        if (villageCamera == null) return;
        if (Input.touchCount == 1)
        {
            Touch t = Input.GetTouch(0);
            if (t.phase == TouchPhase.Began) lastPointerPosition = t.position;
            else if (t.phase == TouchPhase.Moved && t.position.y > Screen.height * .28f)
            {
                Vector2 delta = t.position - lastPointerPosition;
                Vector3 move = new Vector3(-delta.x * .018f, 0f, -delta.y * .018f);
                villageCamera.transform.position += move;
                villageCamera.transform.position = new Vector3(
                    Mathf.Clamp(villageCamera.transform.position.x, -9f, 9f),
                    villageCamera.transform.position.y,
                    Mathf.Clamp(villageCamera.transform.position.z, -27f, -10f));
                lastPointerPosition = t.position;
            }
        }
        else if (Input.touchCount >= 2)
        {
            Touch a = Input.GetTouch(0), b = Input.GetTouch(1);
            float distance = Vector2.Distance(a.position, b.position);
            if (lastPinchDistance > 0f)
                villageCamera.orthographicSize = Mathf.Clamp(villageCamera.orthographicSize + (lastPinchDistance - distance) * .012f, 8f, 19f);
            lastPinchDistance = distance;
        }
        else
        {
            lastPinchDistance = 0f;
            if (Input.GetMouseButtonDown(0)) lastPointerPosition = Input.mousePosition;
            else if (Input.GetMouseButton(0) && Input.mousePosition.y > Screen.height * .28f)
            {
                Vector2 current = Input.mousePosition;
                Vector2 delta = current - lastPointerPosition;
                villageCamera.transform.position += new Vector3(-delta.x * .018f, 0f, -delta.y * .018f);
                villageCamera.transform.position = new Vector3(
                    Mathf.Clamp(villageCamera.transform.position.x, -9f, 9f),
                    villageCamera.transform.position.y,
                    Mathf.Clamp(villageCamera.transform.position.z, -27f, -10f));
                lastPointerPosition = current;
            }
            if (Input.mouseScrollDelta.y != 0f)
                villageCamera.orthographicSize = Mathf.Clamp(villageCamera.orthographicSize - Input.mouseScrollDelta.y, 8f, 19f);
        }
    }

    void Income(){gold+=15+tavernLevel*2;food+=1+farmLevel;wood+=3;Refresh();}
    void Upgrade(){int cost=tavernLevel*100;if(gold<cost){status.text="Not enough gold. Wait for income.";return;}gold-=cost;tavernLevel++;status.text="Moonlit Tavern upgraded!";Refresh();SaveGame();}
    void BuildNewBuilding()
    {
        const int goldCost = 140;
        const int woodCost = 90;
        if (gold < goldCost || wood < woodCost)
        {
            status.text = "Building costs 140 gold and 90 wood. Gather resources and try again.";
            return;
        }
        gold -= goldCost;
        wood -= woodCost;
        buildingsBuilt++;
        CreatePlayerBuilding(buildingsBuilt);
        status.text = "New cottage built! Buildings constructed: " + buildingsBuilt;
        Refresh();
        SaveGame();
    }

    void RestorePlayerBuildings()
    {
        for (int i = 1; i <= buildingsBuilt; i++) CreatePlayerBuilding(i);
    }

    void CreatePlayerBuilding(int index)
    {
        int slot = index - 1;
        float x = -11f + (slot % 4) * 3.4f;
        float z = (slot / 4) % 2 == 0 ? 8.2f : -8.4f;
        if (Mathf.Abs(x) < 4.5f) x += 5.2f;
        Material walls = MakeMat(new Color(.88f, .72f, .58f));
        Material roof = MakeMat(index % 2 == 0 ? new Color(.36f,.46f,.72f) : new Color(.68f,.31f,.39f));
        Material timber = MakeMat(new Color(.31f,.19f,.15f));
        House("Player Cottage " + index, new Vector3(x, 0f, z), walls, roof, timber);
    }

    void UpgradeFarm()
    {
        int goldCost = farmLevel * 75;
        int woodCost = farmLevel * 60;
        if (gold < goldCost || wood < woodCost) { status.text="Farm upgrade needs "+goldCost+" gold and "+woodCost+" wood."; return; }
        gold -= goldCost; wood -= woodCost; farmLevel++;
        status.text="Farm upgraded to Lv. "+farmLevel+"! Food income increased.";
        Refresh(); SaveGame();
    }
    void Recruit()
    {
        if(crystals<5){status.text="You need 5 crystals to summon a hero.";return;}
        crystals-=5; heroesOwned++; status.text="A new hero joined your village! Heroes collected: "+heroesOwned;
        Refresh(); SaveGame();
    }

    void ShowQuest()
    {
        if (questClaimed) { status.text="Daily quest complete! Come back after your next adventure."; return; }
        status.text="QUEST: Upgrade the Moonlit Tavern. Reward: 120 gold + 2 crystals.";
        if (tavernLevel > 1)
        {
            gold += 120; crystals += 2; questsCompleted++; questClaimed = true;
            status.text="Quest completed! +120 gold, +2 crystals."; Refresh(); SaveGame();
        }
        else status.text += " Upgrade it first, then tap QUESTS again to claim.";
    }

    void ShowHeroes()
    {
        status.text="HERO COLLECTION ("+heroesOwned+"): Eliana · Liara · Kael · Meiri · Celestra. Recruit costs 5 crystals.";
    }

    void TradeResources()
    {
        if (food < 10) { status.text="Need at least 10 food to trade."; return; }
        food -= 10; gold += 35; status.text="Trade complete: 10 food exchanged for 35 gold."; Refresh(); SaveGame();
    }

    void Refresh()
    {
        if(resources!=null) resources.text="✦ "+gold+"     ◈ "+crystals+"     ◆ "+food+"     ▰ "+wood;
        if(level!=null) level.text="Tavern Lv. "+tavernLevel+" · Farm Lv. "+farmLevel+" · Houses: "+(4+buildingsBuilt)+" · Villagers: "+residents.Count;
    }

    void SaveGame()
    {
        PlayerPrefs.SetInt("neb_gold",gold); PlayerPrefs.SetInt("neb_crystals",crystals);
        PlayerPrefs.SetInt("neb_food",food); PlayerPrefs.SetInt("neb_wood",wood);
        PlayerPrefs.SetInt("neb_tavern",tavernLevel); PlayerPrefs.SetInt("neb_farm",farmLevel); PlayerPrefs.SetInt("neb_buildings",buildingsBuilt); PlayerPrefs.SetInt("neb_heroes",heroesOwned);
        PlayerPrefs.SetInt("neb_quests",questsCompleted); PlayerPrefs.SetInt("neb_quest_claimed",questClaimed?1:0);
        PlayerPrefs.SetFloat("neb_day_clock",dayClock); PlayerPrefs.Save();
    }

    void LoadGame()
    {
        gold=PlayerPrefs.GetInt("neb_gold",gold); crystals=PlayerPrefs.GetInt("neb_crystals",crystals);
        food=PlayerPrefs.GetInt("neb_food",food); wood=PlayerPrefs.GetInt("neb_wood",wood);
        tavernLevel=PlayerPrefs.GetInt("neb_tavern",tavernLevel); farmLevel=PlayerPrefs.GetInt("neb_farm",farmLevel); buildingsBuilt=PlayerPrefs.GetInt("neb_buildings",buildingsBuilt); heroesOwned=PlayerPrefs.GetInt("neb_heroes",heroesOwned);
        questsCompleted=PlayerPrefs.GetInt("neb_quests",questsCompleted);
        questClaimed=PlayerPrefs.GetInt("neb_quest_claimed",0)==1;
        dayClock=PlayerPrefs.GetFloat("neb_day_clock",dayClock);
    }

    void LoadAndRefresh(){LoadGame();Refresh();status.text="Saved village restored.";}
    void OnApplicationPause(bool paused){if(paused)SaveGame();}
    void OnApplicationQuit(){SaveGame();}
    void OnDestroy(){SaveGame();foreach(var m in materials)if(m!=null)Destroy(m);}
}