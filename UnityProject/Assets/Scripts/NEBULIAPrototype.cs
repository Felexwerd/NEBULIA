using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections.Generic;

public class NEBULIAPrototype : MonoBehaviour
{
    int gold = 420, crystals = 12, food = 86, wood = 120, tavernLevel = 1;
    int heroesOwned = 2, questsCompleted = 0;
    bool questClaimed = false;
    Text resources, status, level;
    Font font;
    Light sunLight;
    float dayClock = 0.22f;
    float saveClock;
    readonly List<Material> materials = new List<Material>();

    void Start()
    {
        Application.targetFrameRate = 60;
        LoadGame();
        BuildVillage();
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
        Box("Meadow",new Vector3(0,-.35f,0),new Vector3(34,.5f,26),grass);
        Box("Main road",new Vector3(0,-.06f,0),new Vector3(3.4f,.08f,26),road);
        Box("Crossroad",new Vector3(-3.2f,-.05f,1.7f),new Vector3(19,.09f,2.5f),road);
        Box("River",new Vector3(12,-.02f,0),new Vector3(3.2f,.1f,26),water);
        for(int i=-5;i<=5;i++) Box("Bridge plank",new Vector3(10.1f,.06f,i*.42f),new Vector3(3.4f,.12f,.34f),woodMat);
        House("Moonlit Tavern",new Vector3(-7.5f,0,4.8f),wall,red,woodMat);
        House("Sunrise Farm",new Vector3(6.5f,0,5.4f),wall,blue,woodMat);
        House("Craftsman's Hall",new Vector3(-7,0,-5.4f),wall,blue,woodMat);
        House("Village Cottage",new Vector3(5.8f,0,-5.8f),wall,red,woodMat);
        for(int i=0;i<22;i++){
            float x=-15+(i*1.73f)%28, z=-11+(i*3.17f)%22;
            if(Mathf.Abs(x)<3||Mathf.Abs(x-12)<3) continue;
            var trunk=GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            trunk.transform.position=new Vector3(x,.55f,z); trunk.transform.localScale=new Vector3(.22f,.55f,.22f);
            trunk.GetComponent<Renderer>().sharedMaterial=woodMat;
            var crown=GameObject.CreatePrimitive(PrimitiveType.Sphere);
            crown.transform.position=new Vector3(x,1.45f,z); crown.transform.localScale=Vector3.one*1.25f;
            crown.GetComponent<Renderer>().sharedMaterial=leaves;
        }
        for(int i=0;i<7;i++){
            var v=GameObject.CreatePrimitive(PrimitiveType.Capsule);
            v.name="Village resident"; v.transform.position=new Vector3(-4+i*1.25f,.62f,Mathf.Sin(i*1.7f)*2);
            v.transform.localScale=new Vector3(.42f,.62f,.42f);
            v.GetComponent<Renderer>().sharedMaterial=MakeMat(Color.Lerp(new Color(.48f,.72f,.91f),new Color(.94f,.53f,.64f),i/6f));
            var h=GameObject.CreatePrimitive(PrimitiveType.Sphere);
            h.transform.position=v.transform.position+Vector3.up*.78f; h.transform.localScale=Vector3.one*.38f;
            h.GetComponent<Renderer>().sharedMaterial=wall;
        }
        var lightObj=new GameObject("Afternoon sunlight"); var light=lightObj.AddComponent<Light>();
        light.type=LightType.Directional; light.intensity=1.35f; light.color=new Color(1,.86f,.71f);
        sunLight = light;
        lightObj.transform.rotation=Quaternion.Euler(48,-32,0);
        RenderSettings.ambientLight=new Color(.62f,.69f,.76f);
        var camObj=new GameObject("Village Camera"); camObj.tag="MainCamera";
        var cam=camObj.AddComponent<Camera>(); cam.transform.position=new Vector3(0,20,-23);
        cam.transform.rotation=Quaternion.Euler(43,0,0); cam.orthographic=true; cam.orthographicSize=14.5f;
        cam.backgroundColor=new Color(.55f,.76f,.87f); cam.clearFlags=CameraClearFlags.SolidColor;
    }

    void House(string n,Vector3 p,Material wall,Material roof,Material woodMat)
    {
        Box(n+" walls",p+new Vector3(0,1.1f,0),new Vector3(3.1f,2.1f,2.7f),wall);
        Box(n+" roof",p+new Vector3(0,2.5f,0),new Vector3(3.5f,.45f,3.1f),roof);
        Box(n+" door",p+new Vector3(0,.55f,-1.37f),new Vector3(.6f,1.1f,.1f),woodMat);
        Box(n+" porch",p+new Vector3(0,.1f,-1.65f),new Vector3(1.8f,.15f,.8f),woodMat);
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
        AddButton(co.transform,"RESTORE",new Vector2(.5f,0),new Vector2(300,35),new Vector2(260,52),new Color(.34f,.38f,.48f),LoadAndRefresh);
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
        saveClock += Time.deltaTime;
        if (saveClock >= 30f) { SaveGame(); saveClock = 0f; }
    }

    void Income(){gold+=15+tavernLevel*2;food+=2;wood+=3;Refresh();}
    void Upgrade(){int cost=tavernLevel*100;if(gold<cost){status.text="Not enough gold. Wait for income.";return;}gold-=cost;tavernLevel++;status.text="Moonlit Tavern upgraded!";Refresh();SaveGame();}
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
        if(level!=null) level.text="Moonlit Tavern · Lv. "+tavernLevel;
    }

    void SaveGame()
    {
        PlayerPrefs.SetInt("neb_gold",gold); PlayerPrefs.SetInt("neb_crystals",crystals);
        PlayerPrefs.SetInt("neb_food",food); PlayerPrefs.SetInt("neb_wood",wood);
        PlayerPrefs.SetInt("neb_tavern",tavernLevel); PlayerPrefs.SetInt("neb_heroes",heroesOwned);
        PlayerPrefs.SetInt("neb_quests",questsCompleted); PlayerPrefs.SetInt("neb_quest_claimed",questClaimed?1:0);
        PlayerPrefs.SetFloat("neb_day_clock",dayClock); PlayerPrefs.Save();
    }

    void LoadGame()
    {
        gold=PlayerPrefs.GetInt("neb_gold",gold); crystals=PlayerPrefs.GetInt("neb_crystals",crystals);
        food=PlayerPrefs.GetInt("neb_food",food); wood=PlayerPrefs.GetInt("neb_wood",wood);
        tavernLevel=PlayerPrefs.GetInt("neb_tavern",tavernLevel); heroesOwned=PlayerPrefs.GetInt("neb_heroes",heroesOwned);
        questsCompleted=PlayerPrefs.GetInt("neb_quests",questsCompleted);
        questClaimed=PlayerPrefs.GetInt("neb_quest_claimed",0)==1;
        dayClock=PlayerPrefs.GetFloat("neb_day_clock",dayClock);
    }

    void LoadAndRefresh(){LoadGame();Refresh();status.text="Saved village restored.";}
    void OnApplicationPause(bool paused){if(paused)SaveGame();}
    void OnApplicationQuit(){SaveGame();}
    void OnDestroy(){SaveGame();foreach(var m in materials)if(m!=null)Destroy(m);}
}